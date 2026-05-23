#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define STRIDE 4096

struct Node {
    void *next_layer;
    uint64_t data_value;
} __attribute__((aligned(16)));

static struct Node root_node __attribute__((aligned(16)));
static struct Node *layer2 = NULL;
static struct Node *layer3 = NULL;
static uint64_t final_target_data = 0;

void init_production_matrix(void) {
    layer3 = (struct Node *)malloc(STRIDE * 2);
    layer2 = (struct Node *)malloc(STRIDE * 2);
    
    struct Node *real_layer3 = (struct Node *)(((uintptr_t)layer3 + STRIDE) & ~(STRIDE - 1));
    struct Node *real_layer2 = (struct Node *)(((uintptr_t)layer2 + STRIDE) & ~(STRIDE - 1));
    
    final_target_data = 987654321ULL;
    
    real_layer3->next_layer = (void *)&final_target_data;
    real_layer3->data_value = 0x3333;
    
    real_layer2->next_layer = (void *)real_layer3;
    real_layer2->data_value = 0x2222;
    
    root_node.next_layer = (void *)real_layer2;
    root_node.data_value = 0x1111;
}

uint64_t standard_lookup(void) {
    struct Node *n2 = (struct Node *)root_node.next_layer;
    struct Node *n3 = (struct Node *)n2->next_layer;
    uint64_t *val_ptr = (uint64_t *)n3->next_layer;
    return *val_ptr;
}

uint64_t accelerated_lookup(void) {
    struct Node *r_ptr = &root_node;
    
    asm volatile (
        "mov x4, %0\n\t"
        "ldp x0, x1, [x4]\n\t"
        "ldp x2, x3, [x0]\n\t"
        "ldp x5, x6, [x2]\n\t"
        : : "r"(r_ptr) : "x0","x1","x2","x3","x4","x5","x6","memory"
    );
    
    struct Node *n2 = (struct Node *)root_node.next_layer;
    struct Node *n3 = (struct Node *)n2->next_layer;
    uint64_t *val_ptr = (uint64_t *)n3->next_layer;
    return *val_ptr;
}

int main(void) {
    init_production_matrix();
    
    printf("\n============================================================\n");
    printf("        PRODUCTION PRODUCTION MATRIX EXECUTIONS             \n");
    printf("============================================================\n");
    
    uint64_t res_std = standard_lookup();
    printf("  [Standard]    Retrieved Data: %llu\n", res_std);
    
    uint64_t res_acc = accelerated_lookup();
    printf("  [Accelerated] Retrieved Data: %llu\n", res_acc);
    printf("============================================================\n\n");
    
    free(layer2);
    free(layer3);
    return 0;
}
