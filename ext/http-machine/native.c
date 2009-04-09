#include <native.h>

VALUE mHTTPMachine;

void Init_native()
{
	mHTTPMachine = rb_const_get(rb_cObject, rb_intern("HTTPMachine"));
	
	init_http_machine_easy();
}