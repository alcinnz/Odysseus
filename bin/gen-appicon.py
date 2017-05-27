#! /usr/bin/python3
from math import sin, cos, pi
TAU = 2*pi
import cairo
from colorsys import hsv_to_rgb

def draw_image(SIZE, BASELINE, DOTS, DOT_RADIUS = 2):
    COLOUR = (0, 0.25, 0.3)
    CENTER = SIZE / 2
    RADIUS = SIZE / 2 - BASELINE
    DOT_COLOUR = (247/255, 120/255, 91/255)
    ANGLE = TAU/DOTS

    out = cairo.SVGSurface("out-{}.svg".format(SIZE), SIZE, SIZE)
    cx = cairo.Context(out)

    cx.set_source_rgb(*COLOUR)
    cx.set_line_width(0.25)

    for i in range(DOTS):
        x = CENTER + cos(ANGLE*i)*RADIUS
        y = CENTER + sin(ANGLE*i)*RADIUS
        
        for j in range(DOTS):
            to_x = CENTER + cos(ANGLE*j)*RADIUS
            to_y = CENTER + sin(ANGLE*j)*RADIUS

            cx.move_to(x, y)
            cx.line_to(to_x, to_y)
            cx.stroke()

    cx.set_source_rgb(*DOT_COLOUR)
    for i in range(DOTS):
        cx.set_source_rgb(*hsv_to_rgb(ANGLE*i, 1, 1))
        x = CENTER + cos(ANGLE*i)*RADIUS
        y = CENTER + sin(ANGLE*i)*RADIUS
        
        cx.arc(x, y, DOT_RADIUS, 0, TAU)
        cx.fill()

draw_image(16, 1, 5, DOT_RADIUS = 1)
draw_image(24, 2, 6, DOT_RADIUS = 1)
draw_image(32, 2, 7, DOT_RADIUS = 2)
draw_image(48, 3, 8, DOT_RADIUS = 2)
draw_image(64, 4, 9, DOT_RADIUS = 3)
draw_image(128, 9, 9, DOT_RADIUS = 5)
draw_image(256, 9, 9, DOT_RADIUS = 5)
