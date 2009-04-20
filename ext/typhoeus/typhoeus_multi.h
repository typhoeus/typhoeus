#ifndef TYPHOEUS_MULTI
#define TYPHOEUS_MULTI

#include <native.h>
#include <http_machine_easy.h>

VALUE cTyphoeusMulti;
typedef struct {
	int running;
	int active;
	CURLM *multi;
} CurlMulti;

void init_http_machine_multi();

#endif