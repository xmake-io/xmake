%module example
%{
extern int fact(int n);
%}
extern int fact(int n);

%include "example2.i"
