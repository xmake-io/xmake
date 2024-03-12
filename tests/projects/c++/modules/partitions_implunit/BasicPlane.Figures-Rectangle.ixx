export module BasicPlane.Figures:Rectangle;

import :Point;

export struct Rectangle {
    Point ul, lr;
};

export int area(const Rectangle& r);
export int height(const Rectangle& r);
export int width(const Rectangle& r);
