cat << 'EOF' > benchmark_m1.c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#define ITERATIONS 40000000
#define MATRIX_SIZE 8388608
struct Node { struct Node* next; uint64_t padding; };
struct LDPNode { struct LDPNode* next[2]; } __attribute__((aligned(16)));
void shuffle(uint32_t *array, uint32_t n) { if (n > 1) { for (uint32_t i = 0; i < n - 1; i++) { uint32_t j = i + rand() / (RAND_MAX / (n - i) + 1); uint32_t t = array[j]; array[j] = array[i]; array[i] = t; } } }
int main() { srand(42); uint32_t* indices1 = malloc(sizeof(uint32_t) * MATRIX_SIZE); uint32_t* indices2 = malloc(sizeof(uint32_t) * MATRIX_SIZE); for (uint32_t i = 0; i < MATRIX_SIZE; i++) { indices1[i] = i; indices2[i] = i; } shuffle(indices1, MATRIX_SIZE); shuffle(indices2, MATRIX_SIZE); struct Node* std_nodes = malloc(sizeof(struct Node) * MATRIX_SIZE); struct LDPNode* ldp_nodes = malloc(sizeof(struct LDPNode) * MATRIX_SIZE); for (uint32_t i = 0; i < MATRIX_SIZE; i++) { std_nodes[i].next = &std_nodes[indices1[i]]; } for (uint32_t i = 0; i < MATRIX_SIZE; i++) { ldp_nodes[i].next[0] = &ldp_nodes[indices1[i]]; ldp_nodes[i].next[1] = &ldp_nodes[indices2[i]]; } free(indices1); free(indices2); clock_t start, end; double cpu_time_used; uint64_t checksum = 0; struct Node* current_std = std_nodes; start = clock(); for (int i = 0; i < ITERATIONS; i++) { current_std = current_std->next; checksum += (uintptr_t)current_std; } end = clock(); cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC; printf("RAM Standard:         %f s (checksum: %llu)\n", cpu_time_used, (unsigned long long)checksum); checksum = 0; struct LDPNode* current_ldp = ldp_nodes; start = clock(); for (int i = 0; i < ITERATIONS; i++) { struct LDPNode* n0; struct LDPNode* n1; asm volatile ("ldp %0, %1, [%2]" : "=r" (n0), "=r" (n1) : "r" (current_ldp->next) : "memory"); checksum += (uintptr_t)n0; uintptr_t index_selector = ((uintptr_t)n0 >> 4) & 1; current_ldp = (index_selector == 0) ? n0 : n1; } end = clock(); cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC; printf("RAM LDP-MATRIX:       %f s (checksum: %llu)\n", cpu_time_used, (unsigned long long)checksum); free(std_nodes); free(ldp_nodes); return 0; }
EOF
clang -O3 -arch arm64 benchmark_m1.c -o benchmark_m1 && ./benchmark_m1
