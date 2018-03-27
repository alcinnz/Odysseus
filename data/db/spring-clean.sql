DELETE FROM screenshot WHERE uri NOT IN (SELECT uri FROM page_visit
    ORDER BY visited_at DESC LIMIT 10000 /* union topsites and favs */);
