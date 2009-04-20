#ifndef TYPHOEUS_EASY
#define TYPHOEUS_EASY

#include <native.h>

void init_http_machine_easy();
typedef struct {
	const char *memory;
	int size;
	int read;
} RequestChunk;

typedef struct {
	RequestChunk *request_chunk;
	CURL *curl;
	struct curl_slist *headers;
} CurlEasy;

#endif