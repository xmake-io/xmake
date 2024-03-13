module;

module BasicPlane.Figures;

int area(const Rectangle& r) { return width(r) * height(r); }
int height(const Rectangle& r) { return r.ul.y - r.lr.y; }
int width(const Rectangle& r) { return r.lr.x - r.ul.x; }
