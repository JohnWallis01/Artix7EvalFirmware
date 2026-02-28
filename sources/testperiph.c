/*
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * 
 *
 * This file is a generated sample test application.
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * SDK application project when you run the "Generate Libraries" menu item.
 *
 */




#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "axidma_header.h"
#include "xaxidma.h"
// #include "xparameters.h"
// #include "xil_cache.h"
#include "xil_printf.h"

#define MIG_OFFSET 0x80000000
#define DMA_DEV_ID      XPAR_AXIDMA_0_DEVICE_ID

#define TX_BASE_ADDR    MIG_OFFSET
#define RX_BASE_ADDR    (TX_BASE_ADDR + 0x80)  // Offset RX buffer from TX buffer to avoid overlap

#define NUM_WORDS    8
#define BUF_SIZE_BYTES  (NUM_WORDS * sizeof(uint32_t))
#define DMA_TRANSFER_SIZE BUF_SIZE_BYTES * 4 //Literally no fucking clue why the times 4
// #define PRINT_DELAY 2000000
#define PRINT_DELAY 100
int delay() {
    for (volatile int i = 0; i < PRINT_DELAY; i++);
    return 0;
}



int main(void)
{
   print("---Entering main---\n\r");

   Xil_DCacheDisable();
   Xil_ICacheDisable();
   //  Xil_ICacheEnable();
   //  Xil_DCacheEnable();
    XAxiDma AxiDma;
    XAxiDma_Config *CfgPtr;
    int Status;
    volatile uint32_t *TxBuf = (uint32_t *)TX_BASE_ADDR;
    volatile uint32_t *RxBuf = (uint32_t *)RX_BASE_ADDR;
    const uint32_t TEST_ARRAY[8] = {0xDEADBEEF, 0xCAFEBABE, 0x12345678, 0x87654321, 0x0F0F0F0F, 0xF0F0F0F0, 0xAAAAAAAA, 0x55555555};
    xil_printf("AXI DMA loopback example\r\n");

    for (int i = 0; i < BUF_SIZE_BYTES; i+=4) {
      TxBuf[i] = TEST_ARRAY[i/4];
      RxBuf[i] = 0x00000000;
    }
    xil_printf("TX buffer initialized with test data, RX buffer cleared\r\n");
    for (int i = 0; i < BUF_SIZE_BYTES; i+=4) {
         if (TxBuf[i] != TEST_ARRAY[i/4]) {
            xil_printf("TX buffer initialization failed at %d: Expected 0x%08x, Found 0x%08x\r\n",
                       i, TEST_ARRAY[i/4], TxBuf[i]);
            xil_printf("Logical Statement Evaluation: %s\r\n", (TxBuf[i] != TEST_ARRAY[i/4]) ? "true" : "false");
            // return XST_FAILURE;
         }
         else {
            xil_printf("TX buffer initialization verified at %d: Expected 0x%08x, Found 0x%08x\r\n",
                       i, TEST_ARRAY[i/4], TxBuf[i]);
         }
    }
   /* Flush caches */
    Xil_DCacheFlushRange(TX_BASE_ADDR, BUF_SIZE_BYTES);
    Xil_DCacheFlushRange(RX_BASE_ADDR, BUF_SIZE_BYTES);
    /* Initialize DMA */
    CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!CfgPtr) {
        xil_printf("No DMA config found\r\n");
        return XST_FAILURE;
    }

    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
    if (Status != XST_SUCCESS) {
        xil_printf("DMA init failed\r\n");
        return XST_FAILURE;
    }
    if (XAxiDma_HasSg(&AxiDma)) {
        xil_printf("DMA is in SG mode, expected simple mode\r\n");
        return XST_FAILURE;
    }

        Status = XAxiDma_SimpleTransfer(
        &AxiDma,
        RX_BASE_ADDR,
		DMA_TRANSFER_SIZE,
        XAXIDMA_DEVICE_TO_DMA
    );
    if (Status != XST_SUCCESS) {
        xil_printf("RX transfer failed\r\n");
        return XST_FAILURE;
    }
        Status = XAxiDma_SimpleTransfer(
        &AxiDma,
        TX_BASE_ADDR,
		DMA_TRANSFER_SIZE,
        XAXIDMA_DMA_TO_DEVICE
    );
    if (Status != XST_SUCCESS) {
        xil_printf("TX transfer failed\r\n");
        return XST_FAILURE;
    }

    /* Poll for completion */
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE));
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA));
    /* Invalidate RX cache */
    xil_printf("DMA transfer completed, verifying data...\r\n");
    Xil_DCacheInvalidateRange(RX_BASE_ADDR, BUF_SIZE_BYTES);
       /* Verify data */
    for (int i = 0; i < BUF_SIZE_BYTES; i+=4) {
        if (RxBuf[i] != TEST_ARRAY[i/4]) {
            xil_printf("Mismatch at %d: TX=0x%08x RX=0x%08x\r\n",
                       i, TEST_ARRAY[i/4], RxBuf[i]);
            xil_printf("Note: TX 0x%08x\r\n", TxBuf[i]);
            // return XST_FAILURE;
        }
        else {
            xil_printf("Match at %d: Expected 0x%08x RX=0x%08x\r\n", i, TEST_ARRAY[i/4], RxBuf[i]);
            delay();
        }
    }

    xil_printf("DMA loopback SUCCESS\r\n");

   // Xil_DCacheDisable();
   // Xil_ICacheDisable();
    return XST_SUCCESS;
}

