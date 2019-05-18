function msg(text) {
	window.webkit.messageHandlers.liberate.postMessage (text);
}

function meta(name) {
	const metas = document.getElementsByTagName('meta');
	let value = null;
	for (let i = 0; i < metas.length; i++)
		if (metas[i].getAttribute('property') === name)
			value = metas[i].getAttribute('content');

	name = name.replace("og:","");
	//msg(name+"="+value);
	return value;
}

function simplify(node) {
	const allowed_attributes = ["src","href"];
	const attributes = node.attributes;
	if (attributes) {
		for (i = 0; i < attributes.length; i++) {
			let name = attributes[i].name;
			if (!allowed_attributes.includes(name))
				node.removeAttribute(name);
		}

		if (node.getAttribute("rel"))
			node.removeAttribute("rel");
	}

	if (node.className)
		delete node.className;

	node.childNodes.forEach(child => simplify(child));
}

function append(content, where) {
	if (!where) where = document.body;
	where.innerHTML += content;
}

function deepText(hoo) {
	let A = [];
	if (hoo) {
		hoo = hoo.firstChild;
		while (hoo != null){
			if (hoo.nodeType == 3)
				A[A.length] = hoo.data;
			else
				A = A.concat(arguments.callee(hoo));

			hoo = hoo.nextSibling;
		}
	}
	return A;
}

function countWords() {
	let elem = document.body;
	let text = deepText(elem).join(' ');
	return text.match(/[A-Za-z\'\-]+/g).length;
}

function theme(name) {
	document.documentElement.className = name;

	// WebKit does not repaint everything if responsive size units are used
	// This function repaints the page manually if it is resized
	window.onresize = function (event) {
		document.body.style.zIndex = Math.floor(Math.random()*10) + 1;
	};
}

function patch() {
	NodeList.prototype.forEach = Array.prototype.forEach;

	let article = new Readability(document).parse();
	let url = meta("og:url");
	let title = article.title || meta("og:title");
	let description = meta("og:description") || article.excerpt;
	let image = meta("og:image");

	document.write('<html><body><header></header></body></html>');
	let header = document.getElementsByTagName("header")[0];

	if (article.byline) append(`<h5>${article.byline}</h5>`, header);
	append(`<h1>${title}</h1>`, header);
	append(`<h4 id="time"></h4>`, header);
	append(`<div></div>`, header);
	append(article.content);

	let read_time = Math.ceil(countWords() / 200);
	document.getElementById("time").innerHTML = `${read_time} minutes`;

	simplify(document.documentElement);
	
	msg("done");
	
	if (reader_theme) theme(reader_theme);
}

patch();
