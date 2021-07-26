/*****************************************************************
*                                                                *
*        Copyright Mentor Graphics Corporation 2014              *
*                                                                *
*                All Rights Reserved.                            *
*                                                                *
*    THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION *
*  WHICH IS THE PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS   *
*  LICENSORS AND IS SUBJECT TO LICENSE TERMS.                    *
*                                                                *
******************************************************************
* $Rev:: 30801         $:  
* [Author:: meltahaw   ]:  
* $Date:: 2020-03-04 1#$:  
*****************************************************************/
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h> 
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <dirent.h>

#if !defined(MGCDRV_FreeBSD)
#include <linux/ioctl.h>
#endif

#include <sys/mman.h>
#include "mgcdrv_api.h"
#include "mgcdrv_pcie_ids.h"

/***********************************************************************************/
/* STATIC */
/***********************************************************************************/

#define MGCDRV_API_LOG_VERBOSE   0   /* 1 for verbose logging, 0 for concise logging */

mgcdrv_appdata_t                *pApp = NULL;
u_int64_t                       ddwLastRand;

#if defined(MGCDRV_FreeBSD)
#define DD_NAME                 "/dev/"DRV_NAME"0"
#else
#define DD_NAME                 "/dev/"DRV_NAME
#endif

#define PRINTF(...)             do{printf("[mgcdrv-api-%d]:",__LINE__);printf(__VA_ARGS__);}while(0);
 
#if (MGCDRV_API_LOG_VERBOSE)
#define FUNC_S()                PRINTF("Enter %s ... \n",__FUNCTION__);
#define FUNC_E()                PRINTF("Exit %s ... \n",__FUNCTION__);
#else
#define FUNC_S()
#define FUNC_E()
#endif

#ifdef LOG_ATOMIC_OPERATIONS
static void u128tos(char *pszBuffer, __uint128_t u128Datum);
#endif

/***********************************************************************************/
/* DEFINITIONS */
/***********************************************************************************/
/**
 * mgcdrv_open: open and init the mgc memory endpoint driver
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
int mgcdrv_open(void)
{
    u_int32_t     aZeros[16];
    u_int32_t     dwVal;
    
    FUNC_S();
    
    pApp = (mgcdrv_appdata_t *)malloc(sizeof(mgcdrv_appdata_t));
    memset(pApp,0,sizeof(mgcdrv_appdata_t));
    
    pApp->fd = open( DD_NAME, O_RDWR);
    if(pApp->fd <0) {
        PRINTF( "Error can't open device %s\n",DD_NAME);
        goto FAILED;
    };
    
    mgcdrv_set_debug_level(0);
        
        
    //mgcdrv_map_regions();    
        
    /** 
        init the first 512bit of bar2 so that bar2_rd_data 
        should has value when do DMA WR w/o memory write first
    */
    memset(aZeros,0,sizeof(aZeros)/sizeof(aZeros[0]));
    mgcdrv_mem_write(aZeros, 0, 16,4); 
    
    /* Set 'AtomicOp Requester Enable' in Ep Cfg Space */
    mgcdrv_cfg_read((u_int32_t*)&dwVal,0xA8,4,1);
    dwVal |= 0x40;
    mgcdrv_cfg_write(dwVal,0xA8,4,1);
    
    printf("mgcdrv version %s, API %s\n",MGCDRV_DRIVER_VERSION,MGCDRV_API_VERSION);
    FUNC_E();
    
    return MGCDRV_OK;    

FAILED:
    free(pApp);
    pApp = NULL;
    return MGCDRV_ERROR;
};

/**
 * mgcdrv_close: close and init the mgc memory endpoint driver
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_close(void)
 {
    FUNC_S();
     
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }
    
    //mgcdrv_unmap_regions();

    close(pApp->fd);  
    PRINTF("Closed the device driver \"%s\" \n",DD_NAME);    

    FUNC_E();
    
    return MGCDRV_OK;
 }
 
 /**
 * map driver regions
 */
 int mgcdrv_map_regions(void)
 {
    int status;
    
    /* setup the mapped regions: Bar0 */
    pApp->cmd.ddwValue = MGCDRV_MAP_DRV;
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_MAP, &pApp->cmd);
    if(status) {
        printf("Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    };    

    pApp->SharedBuf = (u_int64_t) mmap( 0, DRV_BUF_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, pApp->fd, 0 );
    if(MAP_FAILED == (void *)pApp->SharedBuf) {
        PRINTF("Error Cannot map drv buf to user space \n");
        return MGCDRV_ERROR;
    }
    
    /* setup the mapped regions: Bar0 */
    pApp->cmd.ddwValue = MGCDRV_MAP_BAR0;
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_MAP, &pApp->cmd);
    if(status) {
        PRINTF("Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    };    

    pApp->Bar0 = (u_int64_t) mmap( 0, DEF_BAR_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, pApp->fd, 0 );
    if(MAP_FAILED == (void *)pApp->Bar0) {
        PRINTF("Error Cannot map Bar0 to user space \n");
        return MGCDRV_ERROR;
    }    
    
    
    /* setup the mapped regions: Bar2 */
    pApp->cmd.ddwValue = MGCDRV_MAP_BAR2;
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_MAP, &pApp->cmd);
    if(status) {
        PRINTF("Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    };    

    pApp->Bar2 = (u_int64_t) mmap( 0, DEF_BAR_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, pApp->fd, 0 );
    if(MAP_FAILED == (void *)pApp->Bar2) {
        PRINTF("Error Cannot map Bar2 to user space \n");
        return MGCDRV_ERROR;
    }    
    return  MGCDRV_OK;
 }
 
 /**
 * unmap driver regions
 */
 void mgcdrv_unmap_regions(void)
 {
    munmap( (void *)pApp->SharedBuf, DRV_BUF_SIZE );
    munmap( (void *)pApp->Bar0, DEF_BAR_SIZE );
    munmap( (void *)pApp->Bar2, DEF_BAR_SIZE );
 }
 
 /**
 * mgcdrv_read_from_bar
 */
 int mgcdrv_read_from_bar(void *pData, 
                          u_int32_t dwOffset, 
                          u_int32_t dwCount,
                          u_int8_t  bBase,
                          u_int8_t bBar)
 { 
    u_int32_t   i;
    int         status;
    u_int64_t    *pData64 = (u_int64_t*)pData;
    u_int32_t    *pData32 = (u_int32_t*)pData;
    u_int16_t    *pData16 = (u_int16_t*)pData;
    u_int8_t    *pData8  = (u_int8_t *)pData;
    
    FUNC_S();

    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    
    if((bBase != 1) && (bBase !=2) && (bBase !=4) && (bBase !=8)) {
        PRINTF("Invalid bBase value %u, only 1,2,4,8 are possible\n",bBase);
        return MGCDRV_ERROR;        
    }    
    
    pApp->cmd.dwOffset  = dwOffset;
    pApp->cmd.dwBase    = bBase;
    pApp->cmd.dwIndex    = bBar;
     
    for(i=0;i<dwCount;i++) {
        if(bBase == 1) {
            pApp->cmd.dwOffset = dwOffset + i*1;            
        } else if (bBase == 2) {
            pApp->cmd.dwOffset = dwOffset + i*2;                        
        } else if (bBase == 4) {
            pApp->cmd.dwOffset = dwOffset + i*4;                                    
        } else if (bBase == 8) {
            pApp->cmd.dwOffset = dwOffset + i*8;                                    
        } else {
            return MGCDRV_ERROR;        
        }        
        /* trigger ioctl */
        status = ioctl(pApp->fd, MGCDRV_IOCTL_MEM_RD, &pApp->cmd);
        if(status) {
            PRINTF( "Error can't execute ioctl to device %s\n",DD_NAME);
            return MGCDRV_ERROR;
        };  
        
        if(bBase == 1) {
            pData8[i]  = pApp->cmd.ddwValue;
        } else if (bBase == 2) {
            pData16[i] = pApp->cmd.ddwValue;
        } else if (bBase == 4) {
            pData32[i] = pApp->cmd.ddwValue;
        } else if (bBase == 8) {
            pData64[i] = pApp->cmd.ddwValue;
        } else {
            return MGCDRV_ERROR;
        }
    } 
    
    FUNC_E();
    
    return MGCDRV_OK;            
 };
 
 /**
 * mgcdrv_write_to_bar
 */
 int mgcdrv_write_to_bar (const void *pData, 
                          u_int32_t dwOffset, 
                          u_int32_t dwCount,
                          u_int8_t  bBase,
                          u_int8_t bBar)
 { 
    u_int32_t   i;
    int         status;    
    u_int64_t   *pData64 = (u_int64_t*)pData;
    u_int32_t   *pData32 = (u_int32_t*)pData;
    u_int16_t   *pData16 = (u_int16_t*)pData;
    u_int8_t    *pData8  = (u_int8_t *)pData;
    
    FUNC_S(); 

    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    
    if((bBase != 1) && (bBase !=2) && (bBase !=4) && (bBase !=8)) {
        PRINTF("Invalid bBase value %u, only 1,2,4,8 are possible\n",bBase);
        return MGCDRV_ERROR;        
    }    
    
    for(i=0;i<dwCount;i++) {        
        if(bBase == 1) {
            pApp->cmd.ddwValue = pData8[i];
            pApp->cmd.dwOffset = dwOffset + i*1;            
        } else if (bBase == 2) {
            pApp->cmd.ddwValue = pData16[i];            
            pApp->cmd.dwOffset = dwOffset + i*2;                        
        } else if (bBase == 4) {
            pApp->cmd.ddwValue = pData32[i];                        
            pApp->cmd.dwOffset = dwOffset + i*4;                                    
        } else if (bBase == 8) {
            pApp->cmd.ddwValue = pData64[i];
            pApp->cmd.dwOffset = dwOffset + i*8;                                    
        } else {
            return MGCDRV_ERROR;        
        }
        
        pApp->cmd.dwBase    = bBase;
        pApp->cmd.dwIndex   = bBar;
        
        /* trigger ioctl */
        status = ioctl(pApp->fd, MGCDRV_IOCTL_MEM_WR, &pApp->cmd);
        if(status) {
            PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
            return MGCDRV_ERROR;
        };         
    }
    
    FUNC_E();
    
    return MGCDRV_OK;        
 };
 
 /**
 * mgcdrv_mem_read: read memory behind the bridge
 * @field: pData raw data read from memory
 * @field: dwOffset: Starting Write at offset
 * @field: dwLen: number of Bytes/Words/Dwords/DDWords 
 * @field: bBase: Base of Data(1=Byte, 2=Words, 4=/Dwords, 8=DDWords)
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_mem_read(void *pData, 
                     u_int32_t dwOffset, 
                     u_int32_t dwCount,
                     u_int8_t  bBase)
                     
 {
    return mgcdrv_read_from_bar(pData,dwOffset,dwCount,bBase,0);
 }     

 /**
 * mgcdrv_mem_write: write memory behind the bridge
 * @field: pData raw data written to memory
 * @field: dwOffset: Starting Write at offset
 * @field: dwLen: number of Bytes/Words/Dwords/DDWords 
 * @field: bBase: Base of Data(1=Byte, 2=Words, 4=/Dwords, 8=DDWords)
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_mem_write (const void *pData, 
                       u_int32_t dwOffset, 
                       u_int32_t dwCount,
                       u_int8_t  bBase)
 { 
    return mgcdrv_write_to_bar(pData,dwOffset,dwCount,bBase,0);
 };
 
/**
 * mgcdrv_dma_read
 */
 int mgcdrv_dma_read (const u_int8_t *pData, 
                      u_int32_t dwBytes,
                      u_int8_t bIs64Buf)
 { 
    int         status; 
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = 0;
    pApp->cmd.dwLen    = dwBytes;
    pApp->cmd.ddwParam = 0;
    pApp->cmd.dwBase   = (bIs64Buf)?1:0;

    /* copy rx data to user buffer */
    mgcdrv_write_to_drv_buf(pData,dwBytes,pApp->cmd.dwBase);
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_DMA_RD, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();
    
    return MGCDRV_OK;        
 };
 
/**
 * mgcdrv_dma_write
 */
 int mgcdrv_dma_write (u_int8_t *pData, 
                       u_int32_t dwBytes,
                       u_int8_t bIs64Buf)
 { 
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = 0;
    pApp->cmd.dwLen    = dwBytes;
    pApp->cmd.ddwParam = 0;
    pApp->cmd.dwBase   = (bIs64Buf)?1:0;

    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_DMA_WR, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    /* copy rx data to user buffer */
    mgcdrv_read_from_drv_buf(pData,dwBytes,pApp->cmd.dwBase);
    
    FUNC_E();

    return MGCDRV_OK;        
 };
 
/**
 * mgcdrv_dma_read_memory_write_read
 */
 int mgcdrv_dma_read_memory_write_read (const u_int8_t *pData, 
                                        u_int32_t dwBytes,
                                        u_int8_t bIs64Buf)
 { 
    int         status; 
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = 0;
    pApp->cmd.dwLen    = dwBytes;
    pApp->cmd.ddwParam = 0;
    pApp->cmd.dwBase   = (bIs64Buf)?1:0;

    /* copy rx data to user buffer */
    mgcdrv_write_to_drv_buf(pData,dwBytes,pApp->cmd.dwBase);
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_DMA_RD_MEM_WR_RD, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();
    
    return MGCDRV_OK;        
 };
 
/**
 * mgcdrv_dma_write_memory_write_read
 */
 int mgcdrv_dma_write_memory_write_read(u_int8_t *pData, 
                                        u_int32_t dwBytes,
                                        u_int8_t bIs64Buf)
 { 
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = 0;
    pApp->cmd.dwLen    = dwBytes;
    pApp->cmd.ddwParam = 0;
    pApp->cmd.dwBase   = (bIs64Buf)?1:0;

    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_DMA_WR_MEM_WR_RD, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    /* copy rx data to user buffer */
    mgcdrv_read_from_drv_buf(pData,dwBytes,pApp->cmd.dwBase);
    
    FUNC_E();

    return MGCDRV_OK;        
 };
 
 /**
 * mgcdrv_cfg_read: Read from Cfg Space of the Root port or endpoint
 * @field: pValue pointer to the data.
 * @field: wReg register at the configuration space.
 * @field: bLen Number of bytes of Register (1,2,4).
 * @field: bIsEp '1' for Ep, '0' for Root port
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_cfg_read (u_int32_t *pValue, 
                      u_int16_t wReg,
                      u_int8_t bLen,
                      u_int8_t bIsEp)
 {
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.dwLen       = bLen;
    pApp->cmd.dwOffset = wReg;
    pApp->cmd.ddwParam = bIsEp;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_CFG_RD, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    /* copy rx buffer to pData */    
    *pValue = pApp->cmd.ddwValue;
    
    FUNC_E();

    return MGCDRV_OK; 
 } 
 
 /**
 * mgcdrv_cfg_write: Write to Cfg Space of the Root port or endpoint
 * @field: dwValue the value written.
 * @field: wReg register at the configuration space.
 * @field: bLen Number of bytes of Register (1,2,4).
 * @field: bIsEp '1' for Ep, '0' for Root port
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_cfg_write (u_int32_t dwValue, 
                       u_int16_t wReg,
                       u_int8_t bLen,
                       u_int8_t bIsEp)
 {
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = dwValue;
    pApp->cmd.dwLen    = bLen;
    pApp->cmd.dwOffset = wReg;
    pApp->cmd.ddwParam = bIsEp;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_CFG_WR, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK; 
 }
 
/**
 * mgcdrv_get_bar_size: return the bar size
 * @field: bBar bar number(0 or 2)
 * @field: pSize pointer to size
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_get_bar_size (u_int8_t bBar, u_int32_t *pSize)
 {
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.dwLen    = 0;
    pApp->cmd.dwIndex  = bBar;
    pApp->cmd.dwOffset = 0;
    pApp->cmd.ddwParam = 0;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_GET_BAR_SIZE, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    /* copy rx buffer to pData */
    *pSize = pApp->cmd.ddwValue;
    
    FUNC_E();

    return MGCDRV_OK; 
 }
 
  /**
 * mgcdrv_cfg_write: Enable Debug Level
 * @field: bLevel Debug level(0, 1 or 2)
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_set_debug_level (u_int8_t bLevel)
 {
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
            
    pApp->cmd.ddwValue = bLevel;
    pApp->cmd.dwLen       = 0;
    pApp->cmd.dwOffset = 0;
    pApp->cmd.ddwParam = 0;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_DBG, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK; 
 }
 
 /**
 * mgcdrv_get_info: get info and statistics
 * @field: pInfo pointer to info struct
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_get_info (mgcdrv_info_t *pInfo)
 {
    return MGCDRV_OK; 
 }
 
 /**
 * mgcdrv_read_mmio_dword_at_bar: read from the bars memory
 * @field: wOffset: Starting Write at offset
 * @field: bBar which Bar(0,2) 
 * @field: pdwData: Dword pointer
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_read_mmio_dword_at_bar(u_int16_t wOffset, 
                                   u_int8_t bBar,
                                   u_int32_t *pdwData)
 {
    return mgcdrv_read_from_bar(pdwData,wOffset,1,4,bBar);
 }
 
 /**
 * mgcdrv_write_mmio_dword_at_bar: read from the bars memory
 * @field: wOffset: Starting Write at offset
 * @field: bBar which Bar(0,2) 
 * @field: pdwData: Dword pointer
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_write_mmio_dword_at_bar(u_int16_t wOffset, 
                                    u_int8_t bBar,
                                    u_int32_t dwData)
 {
    return mgcdrv_write_to_bar(&dwData,wOffset,1,4,bBar);
 }
 
 /**
 * mgcdrv_get_drv_physical_address: get the physical address of drv buf
 * @field: pddwAddress: address pointer
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_get_drv_physical_address(u_int64_t *pddwAddress, 
                                     u_int8_t bIs64Buf)
 {   
    int         status;  
    FUNC_S();

    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    };
    pApp->cmd.dwBase = (bIs64Buf)?1:0;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_GET_BUF_ADD, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    *pddwAddress = pApp->cmd.ddwValue;
    
    FUNC_E();

    return MGCDRV_OK; 
 }
 
 /**
 * mgcdrv_write_to_drv_buf: write to the sys memory
 * @field: pBuf: pointer to raw data
 * @field: dwBytes: number of bytes
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_write_to_drv_buf(const u_int8_t *pBuf,
                             u_int32_t dwBytes,
                             u_int8_t bIs64Buf)
 {
    int         status;  

    FUNC_S();

    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    };
    /* set the buf pointer */
    pApp->cmd.dwBase = (bIs64Buf)?1:0;
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_BUF, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    status = write(pApp->fd,(void *)pBuf,dwBytes);
    //if(status < dwBytes) {
    //    PRINTF("Fail to read from driver, read %d out of %u\n",status,dwBytes);
    //    return MGCDRV_ERROR;
    //}
    
    /* set the buf pointer to 64 */
    pApp->cmd.dwBase = 1;
    
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_BUF, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    return MGCDRV_OK; 
 }
 
 /**
 * mgcdrv_read_from_drv_buf: write to the sys memory
 * @field: pBuf: pointer to raw data
 * @field: dwBytes: number of bytes
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_read_from_drv_buf(u_int8_t *pBuf, 
                              u_int32_t dwBytes,
                              u_int8_t bIs64Buf)
 {
    int         status;  

    FUNC_S();

    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    };
    /* set the buf pointer */
    pApp->cmd.dwBase = (bIs64Buf)?1:0;
    
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_BUF, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    status = read(pApp->fd,pBuf,dwBytes);
    //if(status<dwBytes) {
    //    PRINTF("Fail to write to driver, read %d out of %u\n",status,dwBytes);
    //    return MGCDRV_ERROR;
    //}
    
    /* set the buf pointer to 64 */
    pApp->cmd.dwBase = 1;
    
    status = ioctl(pApp->fd, MGCDRV_IOCTL_SET_BUF, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    };     
    return MGCDRV_OK; 
 }

 /**
 * mgcdrv_init_irq: setup for irq, should be called before mgcdrv_wait_irq
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_init_irq (void)
 {
    int status;
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_INIT_IRQ, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK;     
 }
 
 /**
 * mgcdrv_enable_irq: enable irq and disable polling
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_enable_irq (void)
 {
    int status;
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_ENABLE_IRQ, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK;
 }
 
 /**
 * mgcdrv_disable_irq: disable irq and enable polling
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_disable_irq (void)
 {
    int status;
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_DISABLE_IRQ, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK;
 }
 
 /**
 * mgcdrv_wait_irq: wait for irq
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 int mgcdrv_wait_irq (void)
 {
    int         status;  
    
    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }      
    
    /* trigger ioctl */
    status = ioctl(pApp->fd, MGCDRV_IOCTL_WAIT_IRQ, &pApp->cmd);
    if(status) {
        PRINTF( "Error can't execute ioctl to device %s\n", DD_NAME);
        return MGCDRV_ERROR;
    }; 
    
    FUNC_E();

    return MGCDRV_OK; 
 };
 
 /**
 * get_dwords_from_str: convert stream of data into Dwords
 */
 void get_dwords_from_str(u_int16_t wCount, 
                          u_int32_t *pDw, 
                          const char *pStr)
 {
    char        aStr[1024] ;
    char        *pToken;
    char        *pRest ;
    u_int16_t   wIndex = 0,wPos =0;

    memset(aStr,0,1024);
    memcpy(aStr,pStr,strlen(pStr));
    pRest   = aStr;
    wPos    = wCount-1;
    while ((pToken = strtok_r(pRest,"_", &pRest)) && (wIndex < wCount)) {
        sscanf(pToken,"%x",&pDw[wPos]);
        wIndex++;
        wPos--;
    };
 }
 
 /**
 * mgcdrv_get_random
 */
 u_int64_t mgcdrv_get_random(void)
 { 
    u_int32_t dwSeed;
    dwSeed = ddwLastRand + time(NULL) + getpid() + getppid() + sysconf(_SC_PAGE_SIZE)*sysconf(_SC_PHYS_PAGES);
    srand(dwSeed);
    ddwLastRand = rand();
    return ddwLastRand;
 }
 
 /**
 * mgcdrv_do_verify_atomic
 * @return: MGCDRV_OK
 *          MGCDRV_ERROR
 */
 u_int64_t mgcdrv_do_verify_atomic(const char *pName,
                                   u_int8_t bType,
                                   u_int8_t bIs4DwHdr,
                                   u_int8_t bIsAdd64,
                                   u_int16_t wReqDwSize,
                                   const char *pReqDw,                          
                                   u_int16_t wCplExpectedDwSize,
                                   const char *pCplDw,
                                   u_int16_t wMemDwOffset,
                                   u_int16_t wMemDwSize,
                                   const char *pMemBeforeDw,
                                   const char *pMemAfterDw,
                                   u_int8_t bByteEnable,
                                   u_int8_t bCplExpectedSts)
 {
    u_int64_t                       ddwErrorCode = MGCDRV_OK;
    u_int32_t                       i;
    u_int32_t                       aReqDw[64];
    u_int32_t                       aActualCplDw[64];
    u_int32_t                       aExpectedCplDw[64];
    u_int32_t                       aTargetDw[64];
    u_int32_t                       aResultDw[64];
    u_int32_t                       aTmp[1024];
    u_int32_t                       aExpectedMem[1024];
    u_int32_t                       dwValue;
    u_int32_t                       wCplExpectedBC;
    u_int64_t                       ddwAdd;
    mgcdrv_atomic_info_reg_t        dwInfoReg;
    mgcdrv_atomic_req_param_reg_t   sReqParam;
    mgcdrv_atomic_cpl_param_reg_t   sCplParam;
    mgcdrv_atomic_cpl_param1_reg_t  sCplParam1;

    FUNC_S();
    
    if(pApp == NULL) {
        return MGCDRV_ERROR;        
    }    
    printf("###################################################\n");
    printf("# Run and Verify AtomicOp TestCase \"%s\"\n",pName);
    printf("###################################################\n");
    
    get_dwords_from_str(wReqDwSize,aReqDw,pReqDw);
    get_dwords_from_str(wMemDwSize,aTargetDw,pMemBeforeDw);
    get_dwords_from_str(wMemDwSize,aResultDw,pMemAfterDw);
    wCplExpectedBC = (bType == 2) ? wReqDwSize*2 : wReqDwSize*4; 
    
    /**
        init the target memory before AtomicOp
        and set the expected memory after Atomic 
    */
    for(i=0;i<1024;i++) {
        aExpectedMem[i] = aTmp[i] = mgcdrv_get_random();
    };
    for(i=wMemDwOffset;i<(wMemDwSize+wMemDwOffset);i++) {
        aTmp[i]         = aTargetDw[i-wMemDwOffset];
        aExpectedMem[i] = aResultDw[i-wMemDwOffset];
    };
    mgcdrv_write_to_drv_buf((u_int8_t*)aTmp,sizeof(aTmp)/sizeof(aTmp[0]),bIsAdd64);

    /* Preset AtomicOp Address */
    mgcdrv_get_drv_physical_address(&ddwAdd,bIsAdd64);    
    ddwAdd += wMemDwOffset*4;    
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_LOW, MGCDRV_MAP_BAR2, (u_int32_t)ddwAdd);
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_HIGH, MGCDRV_MAP_BAR2, (u_int32_t)(ddwAdd>>32));

    /* Preset AtomicOp Request operand(s) */
    for(i=0;i<wReqDwSize;i++) {
        mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_REQ_DWORDS + i*4, MGCDRV_MAP_BAR2, aReqDw[i]);
    };
    
    /** 
    *    Preset AtomicOp Completion up to 4DW and the next 
    *    dwords up to total 8DW to check later if wtite more 
    *    than expected  
    */
    get_dwords_from_str(wCplExpectedDwSize,aExpectedCplDw,pCplDw);        
    for(i=0;i<wCplExpectedDwSize;i++) {
        mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_DWORDS + i*4, MGCDRV_MAP_BAR2, mgcdrv_get_random());
    };
    for(i=wCplExpectedDwSize;i<8;i++) {
        aExpectedCplDw[i] = mgcdrv_get_random();        
        mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_DWORDS + i*4, MGCDRV_MAP_BAR2, aExpectedCplDw[i]);
    };    
    
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_PARAM, MGCDRV_MAP_BAR2, 0xFFFFFFFF);
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_PARAM1, MGCDRV_MAP_BAR2, 0xFFFFFFFF);

    /* Construct atomic operation request register value */
    memset(&sReqParam, 0, sizeof(sReqParam));    
    sReqParam.SetHdrSize    = 1;
    sReqParam.HdrSize       = bIs4DwHdr;    
    sReqParam.SetTag        = 1;
    sReqParam.Tag           = mgcdrv_get_random();
    sReqParam.SetBe         = 1;
    sReqParam.FirstBe       = bByteEnable&0x0F;
    sReqParam.LastBe        = bByteEnable>>4;
    memcpy(&dwValue,&sReqParam,4);        
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_REQ_PARAM, MGCDRV_MAP_BAR2, dwValue);

    /* Report Request to User */
    printf("[*]-AtomicOp Request\n");
    printf("\t-Type         : %s-%s\n",GET_ATOMIC_NAME(bType),(bIs4DwHdr)?"4DW":"3DW");
    printf("\t-Address      : %s,0x%08x_%08x, 4k_Decimal(%lu)\n",(bIsAdd64)?"64bit":"32bit",
                                                                 (u_int32_t)(ddwAdd>>32),
                                                                 (u_int32_t)ddwAdd,
                                                                 ddwAdd&0xFFF);
    printf("\t-Length       : %u\n",wReqDwSize);
    printf("\t-Tag          : 0x%x\n", sReqParam.Tag);
    printf("\t-BE           : 0x%x_0x%x\n", sReqParam.LastBe, sReqParam.FirstBe);
    printf("\t-Payload      : ");
    for(i=0;i<wReqDwSize;i++)
        printf("0x%08x ",aReqDw[i]);
    printf("\n");
    
    printf("[*]-Memory Dwords Before Atomic: ");
    mgcdrv_read_from_drv_buf((u_int8_t*)aTmp,sizeof(aTmp)/sizeof(aTmp[0]),bIsAdd64);    
    for(i=(wMemDwOffset)? wMemDwOffset-1 : 0 ;i<wMemDwOffset+wMemDwSize+4;i++)
        printf("%s0x%08x%s ",(i==wMemDwOffset)?"<":"",aTmp[i],(i==(wMemDwOffset+wMemDwSize-1))?">":"");
    printf("\n");
    
    mgcdrv_init_irq();    

    /* Do the AtomicOp */
    memset(&dwInfoReg, 0, sizeof(dwInfoReg));
    dwInfoReg.AtomicInfoType        = bType;  
    dwInfoReg.AtomicInfoOperandLen  = wReqDwSize;
    dwInfoReg.AtomicInfoStart       = 1;
    memcpy(&dwValue,&dwInfoReg,4);            
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_INFO, MGCDRV_MAP_BAR2, dwValue);    
    
    /* Wait for Irq assertion */
    mgcdrv_wait_irq();

    /* Read completion registers */
    mgcdrv_read_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_PARAM, MGCDRV_MAP_BAR2, &dwValue);
    memcpy(&sCplParam,&dwValue,4);    
    mgcdrv_read_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_PARAM1, MGCDRV_MAP_BAR2, &dwValue);    
    memcpy(&sCplParam1,&dwValue,4);


    /* Read completion + Extra Dwords to make sure it wasnot written beyond 4DW */
    for(i=0;i<8;i++) {
        mgcdrv_read_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_CPL_DWORDS + i*4, MGCDRV_MAP_BAR2, &aActualCplDw[i]);
    };
        
    printf("[*]-AtomicOp Completion\n");
    printf("\t-Byte Count   : %u\n",sCplParam.ByteCount);
    printf("\t-Length       : %u\n",sCplParam.Length);
    printf("\t-Status       : 0x%x\n",sCplParam.Status);
    printf("\t-Lower Add    : 0x%x\n",sCplParam.LowerAdd);    
    printf("\t-Tag          : 0x%x\n",sCplParam1.Tag);    
    printf("\t-Payload      : ");
    for(i=0;i<wCplExpectedDwSize;i++)
        printf("0x%08x ",aActualCplDw[i]);
    printf("\n");
    printf("\t-Above Cpl    : ");
    for(i=wCplExpectedDwSize;i<8;i++)
        printf("0x%08x ",aActualCplDw[i]);
    printf("\n");
    
    printf("[*]-Memory Dwords After Atomic: ");
    mgcdrv_read_from_drv_buf((u_int8_t*)aTmp,sizeof(aTmp)/sizeof(aTmp[0]),bIsAdd64);    
    for(i=(wMemDwOffset)? wMemDwOffset-1 : 0 ;i<wMemDwOffset+wMemDwSize+4;i++)
        printf("%s0x%08x%s ",(i==wMemDwOffset)?"<":"",aTmp[i],(i==(wMemDwOffset+wMemDwSize-1))?">":"");
    printf("\n");
    
    
    /**
        Run the checks for AtomicOp 
    */    
    printf("[*]-Run Checks:\n");    
    /* Read sys memory */
    mgcdrv_read_from_drv_buf((u_int8_t*)aTmp,sizeof(aTmp)/sizeof(aTmp[0]),bIsAdd64);
    /* Check for Memory */
    if(memcmp((u_int8_t *)aTmp,(u_int8_t *)aExpectedMem,1024*4) ==0) {
        printf("\t-PASSED : Memory region \n");
    } else {
        printf("\t-FAILED : Memory region \n");
        for(i=0;i<1024;i++){
            if(aTmp[i] != aExpectedMem[i]) {
                printf("\t\t- Expected: Mem[%u] = 0x%08x, Actual: Mem[%u] = 0x%08x\n",
                       i,aExpectedMem[i],i,aTmp[i]);
            };
        };
        ddwErrorCode |= ERR_ATOMIC_MEM;
    }; 
    
    /* Check for Completion Status */
    if(bCplExpectedSts == sCplParam.Status) {
        printf("\t-PASSED : Completion Status\n");
    } else {
        printf("\t-FAILED : Completion Status\n");
        printf("\t\t- Expected: %u, Actual %u\n",bCplExpectedSts,sCplParam.Status);
        ddwErrorCode |= ERR_ATOMIC_CPL_STS;
    };
    
    /* check for Completion Data */
    if(memcmp((u_int8_t *)aExpectedCplDw,(u_int8_t *)aActualCplDw,8*4) == 0) {
        printf("\t-PASSED : Completion Dwords and above up to 8 DW\n");
    } else {
        printf("\t-FAILED : Completion Dwords\n");
        for(i=0;i<8;i++){
            if(aExpectedCplDw[i] != aActualCplDw[i]) {
                printf("\t\t- Expected: CplDW[%u] = 0x%08x, Actual: CplDW[%u] = 0x%08x\n",
                       i,aExpectedCplDw[i],i,aActualCplDw[i]);
            }
        };
        ddwErrorCode |= ERR_ATOMIC_CPL_DATA;
    };
    
    /* Check for Completion Length */    
    if(sCplParam.Length == wCplExpectedDwSize) {
        printf("\t-PASSED : Completion Length\n");
    } else {
        printf("\t-FAILED : Completion Length\n");        
        printf("\t\t- Expected: %u, Actual %u\n",wCplExpectedDwSize,sCplParam.Length);
        ddwErrorCode |= ERR_ATOMIC_CPL_LEN;
    }
    
#if 0
    /* Check for Completion Tag */    
    if(sCplParam1.Tag == sReqParam.Tag) {
        printf("\t-PASSED : Completion Tag\n");
    } else {
        printf("\t-FAILED : Completion Tag\n");
        printf("\t\t- Expected: 0x%02x, Actual 0x%02x\n",sCplParam1.Tag,sReqParam.Tag);
        ddwErrorCode |= ERR_ATOMIC_CPL_TAG;
    }
 #endif
 
    /* Check for Completion Byte Count */
    if(wCplExpectedBC == sCplParam.ByteCount) {
        printf("\t-PASSED : Completion Byte Count\n");
    } else {
        printf("\t-FAILED : Completion Byte Count\n");
        printf("\t\t- Expected: %u, Actual %u\n",wCplExpectedBC,sCplParam.ByteCount);
        ddwErrorCode |= ERR_ATOMIC_CPL_BC;
    };  
       
    /* Check for Completion Lower Address */
    if(sCplParam.LowerAdd == 0) {
        printf("\t-PASSED : Completion Lower Address\n");
    } else {
        printf("\t-FAILED : Completion Lower Address\n");
        printf("\t\t- Expected: %u, Actual %u\n",0,sCplParam.LowerAdd);
        ddwErrorCode |= ERR_ATOMIC_CPL_LOWER_ADD;
    };    
 
    printf("###################################################\n");
    printf("#Finish: ErrorCode 0x%lx\n",ddwErrorCode);
    printf("###################################################\n");

    return ddwErrorCode;        
 };
 
 /**
 * mgcdrv_check_and_log_error
 * @return: void
 */
 void mgcdrv_check_error_code(u_int64_t ddwExpected,u_int64_t ddwVal) 
 {
    if(ddwVal !=ddwExpected) {
        printf("Found Error, expected 0x%lx  value 0x%lx \n\n",ddwExpected,ddwVal);
        pApp->bError = 1;
    };
 };
 
 /**
 * mgcdrv_error_logged
 * @return: Error
 */
  u_int8_t mgcdrv_error_logged(void)
  {
    if(pApp == NULL)
        return 0;
    return pApp->bError;
  }
 
 /**
 * mgcdrv_atomic_init: Initialize an atomic variable within the driver's buffer
 * @field: u16SizeofAtomic, Size in bytes of the atomic variable
 * @field: bIsAdd64, Use 64-bit space if non-zero, use 32-bit space if zero
 * @field: pvInitialValue, Pointer to the initial value to preset
 */
 int mgcdrv_atomic_init(
         u_int32_t  u32SizeofAtomic,
         u_int8_t   bIsAdd64,
         void       *pvInitialValue )
 {
     mgcdrv_write_to_drv_buf(pvInitialValue, u32SizeofAtomic, bIsAdd64);
     return MGCDRV_OK;
 }
 
 /**
 * mgcdrv_atomic_op: initiate AtomicOp Request, wait 
 * for completion, return
 * @field: pAtomicOp, Pointer to a pre-filled-in mgcdrv_atomic_t descriptor
 */
 int mgcdrv_atomic_op(mgcdrv_atomic_op_t *pAtomicOp)
 {
    mgcdrv_atomic_info_reg_t    stInfoReg;
    u_int32_t    dwInfoReg;
    u_int16_t   wOffset;
    u_int64_t    ddwSysMem;
    u_int8_t    bIs64Buf = (pAtomicOp->u32SizeofAddr == sizeof(u_int64_t));
    u_int8_t    bOperandLenDWs;  /* operand buffer len in numof dws */
    bOperandLenDWs = pAtomicOp->u32SizeofOp / sizeof(u_int32_t);
    if (pAtomicOp->u8OpType == MGCDRV_ATOMIC_OP_CAS)
        bOperandLenDWs *= 2;    /* CAS takes two operands */

    mgcdrv_get_drv_physical_address(&ddwSysMem, bIs64Buf);
#ifdef LOG_ATOMIC_OPERATIONS
    char        aszStrint128[48];
    int  i;
    char c = '(';
    printf("Atomic %s-%u",
            (pAtomicOp->u8OpType == MGCDRV_ATOMIC_OP_FADD) ? "FADD" :
            (pAtomicOp->u8OpType == MGCDRV_ATOMIC_OP_SWAP) ? "SWAP" :
            (pAtomicOp->u8OpType == MGCDRV_ATOMIC_OP_CAS ) ? "CAS"  : "ERROR",
            pAtomicOp->u32SizeofOp * 8);
    for (i=0; i < ((pAtomicOp->u8OpType == MGCDRV_ATOMIC_OP_CAS) ? 2 : 1); ++i)
    {
        if (pAtomicOp->u32SizeofOp == sizeof(u_int32_t))
            printf("%c0x%x", c, pAtomicOp->auOperand[i].u32);
        else if (pAtomicOp->u32SizeofOp == sizeof(u_int64_t))
            printf("%c0x%lx", c, pAtomicOp->auOperand[i].u64);
        else if (pAtomicOp->u32SizeofOp == sizeof(__uint128_t))
        {
            u128tos(aszStrint128, pAtomicOp->auOperand[i].u128);
            printf("%c\n   %s", c, aszStrint128);
        }
        c = ',';
    }
    printf(") @ driver buffer(%d) address 0x%lx\n", pAtomicOp->u32SizeofAddr * 8, ddwSysMem);
#endif
    /* program atomic address registers via BAR2 */
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_LOW,  MGCDRV_MAP_BAR2, ddwSysMem);        
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_HIGH, MGCDRV_MAP_BAR2, ddwSysMem>>32);    

    /* Construct atomic operation info register value and save it for later */
    memset(&stInfoReg, 0, sizeof(stInfoReg));
    stInfoReg.AtomicInfoType        = pAtomicOp->u8OpType;
    stInfoReg.AtomicInfoOperandLen  = bOperandLenDWs;
    stInfoReg.AtomicInfoStart  = 1; 
    memcpy(&dwInfoReg, &stInfoReg, sizeof(dwInfoReg));

    wOffset = MGCDRV_REG_ATOMIC_REQ_DWORDS;

    /* Preset atomic operand(s) */
    switch (pAtomicOp->u32SizeofOp)
    {
        case sizeof(u_int32_t):
        {
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    pAtomicOp->auOperand[0].u32);
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    pAtomicOp->auOperand[1].u32);
        }
        break;

        case sizeof(u_int64_t):
        {
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (pAtomicOp->auOperand[0].u64 & 0xFFFFFFFF));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (pAtomicOp->auOperand[0].u64 >> 32));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (pAtomicOp->auOperand[1].u64 & 0xFFFFFFFF));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (pAtomicOp->auOperand[1].u64 >> 32));
        }
        break;

        case sizeof(__uint128_t):
        {
            __uint128_t u128Temp;
            /* First operand */
            u128Temp = pAtomicOp->auOperand[0].u128;
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) u128Temp);
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 32));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 64));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 96));
            wOffset += sizeof(u_int32_t);

            /* Second operand */
            u128Temp = pAtomicOp->auOperand[1].u128;
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) u128Temp);
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 32));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 64));
            wOffset += sizeof(u_int32_t);
            mgcdrv_write_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2,
                    (u_int32_t) (u128Temp >> 96));
        }
        break;

        default:
        {
            return MGCDRV_ERROR;
        }
        break;
    }
    
    mgcdrv_init_irq();
    
    /* Write the info reg to trigger the atomic operation */
    mgcdrv_write_mmio_dword_at_bar(MGCDRV_REG_ATOMIC_INFO, MGCDRV_MAP_BAR2, dwInfoReg);

    /* IRQ signals completion */
    mgcdrv_wait_irq();

    /* Retrieve the returned value */
    wOffset = MGCDRV_REG_ATOMIC_CPL_DWORDS;
    switch (pAtomicOp->u32SizeofOp)
    {
        case sizeof(u_int32_t):
        {
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &pAtomicOp->uReadDatum.u32);
#ifdef LOG_ATOMIC_OPERATIONS
            printf("  completion value = 0x%x\n", pAtomicOp->uReadDatum.u32);
#endif
        }
        break;

        case sizeof(u_int64_t):
        {
            u_int32_t u32ReadPart;
            u_int64_t u64ReadDatum;
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            u64ReadDatum = u32ReadPart;
            wOffset += sizeof(u_int32_t);
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            pAtomicOp->uReadDatum.u64 = u64ReadDatum | (u_int64_t)u32ReadPart << 32;
#ifdef LOG_ATOMIC_OPERATIONS
            printf("  completion value = 0x%lx\n", pAtomicOp->uReadDatum.u64);
#endif
        }
        break;

        case sizeof(__uint128_t):
        {
            u_int32_t u32ReadPart;
            __uint128_t u128ReadDatum;
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            u128ReadDatum = u32ReadPart;
            wOffset += sizeof(u_int32_t);
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            u128ReadDatum |= (__uint128_t) u32ReadPart << 32;
            wOffset += sizeof(u_int32_t);
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            u128ReadDatum |= (__uint128_t) u32ReadPart << 64;
            wOffset += sizeof(u_int32_t);
            mgcdrv_read_mmio_dword_at_bar(wOffset, MGCDRV_MAP_BAR2, &u32ReadPart);
            wOffset += sizeof(u_int32_t);
            pAtomicOp->uReadDatum.u128 = u128ReadDatum | (__uint128_t)u32ReadPart << 96;
#ifdef LOG_ATOMIC_OPERATIONS
            u128tos(aszStrint128, pAtomicOp->uReadDatum.u128);
            printf("  completion value = %s\n", aszStrint128);
#endif
        }
        break;

        default:
            return MGCDRV_ERROR;
    }

    return MGCDRV_OK;
 }

 /**
 * u128tos: Converts a __uint128_t to a string of hex characters
 * @field: pszBuffer - buffer for holding the output (requires 38 bytes)
 * @field: u128Datum - Datum to be converted
 */

#ifdef LOG_ATOMIC_OPERATIONS
static void u128tos(char *pszBuffer, __uint128_t u128Datum)
{
    sprintf(pszBuffer, "0x%08x", (u_int32_t) (u128Datum >> 96));
    sprintf(pszBuffer + strlen(pszBuffer), "_%08x", (u_int32_t) (u128Datum >> 64));
    sprintf(pszBuffer + strlen(pszBuffer), "_%08x", (u_int32_t) (u128Datum >> 32));
    sprintf(pszBuffer + strlen(pszBuffer), "_%08x", (u_int32_t) u128Datum);
}
#endif

mgcdrv_pci_dev_t   *pDevTree = NULL;
u_int16_t           wDevCount = 0;

u_int16_t mgcdrv_pcie_read_sysfile(const char *pPath,
                                   const char *pFile,
                                   u_int16_t wLen,
                                   u_int8_t *pBuf,
                                   u_int16_t wPos)
{
    char aPath[1024];
    int fd;
    int size;
    int status;
    
    sprintf(aPath,"%s/%s",pPath,pFile);
    size = 0;
    
    if((fd = open(aPath,O_RDONLY)) == -1) {
        perror("");
        printf("Error-%d: cannot open pcie sys file \"%s\"\n",__LINE__,aPath);
        return size;
    }
    
    if(wPos) {
        status = lseek(fd,wPos,SEEK_SET);
        if(status == -1) {
            perror("");
            printf("Error-%d: cannot seek %u in the pcie sys file \"%s\"\n",__LINE__,wPos,aPath);        
            return size;        
        }
    }
    
    size = read(fd,pBuf,wLen);
    if(!size){
        perror("");        
        printf("Warn-%d: cannot read %u bytes at loc 0x%x from pcie sys file \"%s\"\n",__LINE__,wLen,wPos,aPath);        
    }
    close(fd);
    return size;
}

u_int16_t mgcdrv_pcie_readi_sysfile(mgcdrv_pci_dev_t *pDev,
                                    const char *pFile,
                                    u_int32_t *pVal)
{
    u_int8_t aVal[8];
    int size;
    size = mgcdrv_pcie_read_sysfile(pDev->aSysPath,pFile,8,aVal,0);
    if(size && pVal) {
       sscanf((const char *) aVal,"%x", pVal);
    }
    return size;
}
u_int16_t mgcdrv_pcie_reads_sysfile(mgcdrv_pci_dev_t *pDev,
                                    const char *pFile,
                                    u_int16_t wLen,
                                    u_int8_t *pBuf)
{
    return mgcdrv_pcie_read_sysfile(pDev->aSysPath,pFile,wLen,pBuf,0);
}
u_int16_t mgcdrv_pcie_read_cfg_sysfile(mgcdrv_pci_dev_t *pDev,
                                       u_int32_t *pVal,
                                       u_int16_t wPos,
                                       u_int8_t bBase)
{
    u_int8_t aVal[32];
    int size;    
    bBase = ((bBase ==4)||(bBase==2)||(bBase==1)) ? bBase : 4;
    size = mgcdrv_pcie_read_sysfile(pDev->aSysPath,"config",bBase,aVal,wPos);    
    if(size && pVal) {
        memcpy(pVal,aVal,bBase);
    }    
    return size;
}

int mgcdrv_scan_pcie_tree(u_int16_t *pCount)
{
    DIR                 *dir;
    struct dirent       *entry;
    mgcdrv_pci_dev_t    *pDev;
    u_int32_t           i;
    
    /* free list */
    if(pDevTree) {
        free(pDevTree);
        wDevCount = 0;
    }
   
    if ((dir = opendir("/sys/bus/pci/devices")) == NULL) {
        perror("cannot open /sys/bus/pci/devices error:");
        return MGCDRV_ERROR;
    }
                printf("%s\n",aPCIDeviceTable[12270].pName);

    printf("open dir /sys/bus/pci/devices is ok\n");
    
    while ((entry = readdir(dir)) != NULL) {
        u_int32_t dwIrq;
        
        /* should be xxxx:x:x:x at min */                
        if(strlen(entry->d_name) < 10) 
            continue;
        
        wDevCount++;
        /* shrink the tree */
        pDev = (mgcdrv_pci_dev_t*)malloc(sizeof(mgcdrv_pci_dev_t)*wDevCount);        
        memset(pDev,0,sizeof(mgcdrv_pci_dev_t)*wDevCount);
        memcpy(pDev,pDevTree,sizeof(mgcdrv_pci_dev_t)*(wDevCount-1));
        free(pDevTree);
        pDevTree = pDev;   
        pDev = &pDevTree[wDevCount-1];
        
        /* fill device info */
        sprintf(pDev->aDirName,"%s",entry->d_name);
        sscanf(pDev->aDirName,"%hx:%hhx:%hhx.%hhu",&pDev->wDomain,&pDev->bBus,&pDev->bDev,&pDev->bFunc);
        sprintf(pDev->aSysPath,"/sys/bus/pci/devices/%s",entry->d_name);
        mgcdrv_pcie_readi_sysfile(pDev,"irq",&dwIrq);
        pDev->bIrq = (u_int8_t) dwIrq;
        
        /* collect sys data */
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->wVendor),0,2);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->wDevice),2,2);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->bClass),8,1);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->bProgIf),9,1);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->bSubClass),10,1);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->bClass),11,1);
        mgcdrv_pcie_read_cfg_sysfile(pDev,(u_int32_t*)&(pDev->bHdrType),14,1);

        sprintf(pDev->aVendor,"%s","UNKNOWN");
        sprintf(pDev->aDevice,"%s","UNKNOWN");
        sprintf(pDev->aClass,"%s","UNKNOWN");
        sprintf(pDev->aSubClass,"%s","UNKNOWN");
        sprintf(pDev->aProgIf,"%s","UNKNOWN");  
        
        for(i=0;i<sizeof(aPCIVendorTable)/sizeof(aPCIVendorTable[0]);i++) {
            if(aPCIVendorTable[i].wVendorID == pDev->wVendor) {
                sprintf(pDev->aVendor,"%s",aPCIVendorTable[i].pName);
                break;
            }
        }   
        
        for(i=0;i<sizeof(aPCIDeviceTable)/sizeof(aPCIDeviceTable[0]);i++) {
            if((aPCIDeviceTable[i].wDeviceID == pDev->wDevice) && (aPCIDeviceTable[i].wVendorID==pDev->wVendor)) {
                sprintf(pDev->aDevice,"%s",aPCIDeviceTable[i].pName);                
                break;
            }
        }

        for(i=0;i<sizeof(aPCIClassTable)/sizeof(aPCIClassTable[0]);i++) {
            if(i==pDev->bClass) {
                sprintf(pDev->aClass,"%s",aPCIClassTable[i].pName);
                break;
            }
        }     

        for(i=0;i<sizeof(aPCISubClassTable)/sizeof(aPCISubClassTable[0]);i++) {
            if((aPCISubClassTable[i].bClass == pDev->bClass) && (aPCISubClassTable[i].bSubClass==pDev->bSubClass)) {
                sprintf(pDev->aSubClass,"%s",aPCISubClassTable[i].pName);                
                break;
            }
        } 
        
        for(i=0;i<sizeof(aPCIProgIfTable)/sizeof(aPCIProgIfTable[0]);i++) {
            if((aPCIProgIfTable[i].bClass == pDev->bClass) && 
               (aPCIProgIfTable[i].bSubClass == pDev->bSubClass)&&
               (aPCIProgIfTable[i].bProgIf == pDev->bProgIf)) {
                sprintf(pDev->aProgIf,"%s",aPCIProgIfTable[i].pName);                
                break;
            }
        }        
        
        //* print if required */
        printf("Found PCIe Device::%s\n",pDev->aSysPath);
        printf("  |-Sys Path: %s\n",pDev->aSysPath);
        printf("  |-Address : %x:%x:%x:%x\n",pDev->wDomain,pDev->bBus,pDev->bDev,pDev->bFunc);
        printf("  |-Vendor  : 0x%x,%s\n",pDev->wVendor,pDev->aVendor);
        printf("  |-Device  : 0x%x,%s\n",pDev->wDevice,pDev->aDevice);
        printf("  |-Class   : 0x%x,%s\n",pDev->bClass,pDev->aClass);
        printf("  |-SubClass: 0x%x,%s\n",pDev->bSubClass,pDev->aSubClass);
    }
    closedir(dir);    
    
    *pCount = wDevCount;
    
    return MGCDRV_OK;    
}
