#ifndef QT_DEMO_GLOBAL_H
#define QT_DEMO_GLOBAL_H

#include <QtCore/qglobal.h>

#if defined(QT_DEMO_LIBRARY)
#  define QT_DEMOSHARED_EXPORT Q_DECL_EXPORT
#else
#  define QT_DEMOSHARED_EXPORT Q_DECL_IMPORT
#endif

#endif // QT_TEST5_GLOBAL_H
