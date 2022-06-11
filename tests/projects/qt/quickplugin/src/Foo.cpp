#include "Foo.h"

Foo::Foo(QObject *parent) : QObject { parent }, m_bar{ 0 } {
}

int Foo::bar() const noexcept {
    return m_bar;
}

void Foo::setBar(int bar) noexcept {
    if (bar == m_bar) return;

    m_bar = bar;

    Q_EMIT barChanged(m_bar);
}