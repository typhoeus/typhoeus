#ifndef TYPHOEUS_NATIVE
#define TYPHOEUS_NATIVE

#include <ruby.h>
#include <curl/curl.h>
#include <curl/easy.h>
#include <curl/multi.h>

void Init_native();
extern VALUE mTyphoeus;
extern void init_typhoeus_easy();
extern void init_typhoeus_multi();

#endif
