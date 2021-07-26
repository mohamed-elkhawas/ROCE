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
* $Rev:: 33572         $:  
* [Author:: meltahaw   ]:   
* $Date:: 2020-09-23 1#$:  
* Description :: Implemented as per the PCI Linux API guide
*   http://lxr.free-electrons.com/source/Documentation/PCI/pci.txt
*****************************************************************/
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/semaphore.h>
#include <linux/cdev.h>
#include <linux/ioport.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <asm/uaccess.h>
#include <linux/io.h>
#include <linux/pci.h>
#include <linux/timer.h>
#include <linux/completion.h>
#include <linux/interrupt.h>
#include <linux/sched.h> 
#include <linux/spinlock_types.h>
#include <asm/io.h>
#include <linux/fs.h>
#include <linux/delay.h>
#include <asm/uaccess.h>
#include <linux/version.h>
#include <linux/async.h>
#include <linux/spinlock.h>

#include "mgcdrv.h"

/***********************************************************************************/
/* Defines */
/***********************************************************************************/
#ifndef __devinit
#define __devinit
#endif

#ifndef __devexit
#define __devexit
#endif

#ifndef __devexit_p
#define __devexit_p(x) x
#endif

#ifdef MGCDRV_DBG
#define __INFO(fmt,...)     	{if(1){printk("Info   [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define __NOTE(fmt,...)     	{if(1){printk("Note   [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define __DBG(fmt,...)      	{if(1){printk("Debug  [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define _ERR(fmt,...)       	{if(1){printk("Error  [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#else
#define __INFO(fmt,...)     	{if(pDrv->bDebugLevel >= 0){printk("Info   [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define __NOTE(fmt,...)     	{if(pDrv->bDebugLevel >= 1){printk("Note   [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define __DBG(fmt,...)      	{if(pDrv->bDebugLevel >= 2){printk("Debug  [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#define _ERR(fmt,...)       	{if(1)                     {printk("Error  [" DRV_NAME "-%d]:",__LINE__); printk(fmt,##__VA_ARGS__);}}
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(4,12,0)
  #define mgc_copy_from_user(...) copy_from_user(__VA_ARGS__)
  #define mgc_copy_to_user(...)   copy_to_user(__VA_ARGS__)
#else
  #define mgc_copy_from_user(...) raw_copy_from_user(__VA_ARGS__)
  #define mgc_copy_to_user(...)   raw_copy_to_user(__VA_ARGS__)
#endif
/***********************************************************************************/
/* PROTOTYPE */
/***********************************************************************************/
static int __devinit mgcdrv_probe(struct pci_dev *, const struct pci_device_id *);
static void __devexit mgcdrv_remove( struct pci_dev *);
static int mgcdrv_init_module( void);
static void mgcdrv_cleanup_module( void);
static int mgcdrv_open( struct inode *, struct file *);
static int mgcdrv_release( struct inode *, struct file *);
static long mgcdrv_ioctl(struct file *, unsigned int, unsigned long);
static int mgcdrv_mmap( struct file * filp,struct vm_area_struct *  vma );
static ssize_t mgcdrv_read(struct file *  filp, char *buf, size_t count, loff_t *offp );
static ssize_t mgcdrv_write(struct file *filp, const char *buf, size_t  count, loff_t *offp );
static void mgcdrv_do_wait_irq(void);
static void async_memory_write_read(void *data, async_cookie_t cookie);
/***********************************************************************************/
/* STATIC */
/***********************************************************************************/
static struct file_operations mgcdrv_fops = 
{
    .owner            = THIS_MODULE,
    .unlocked_ioctl    = mgcdrv_ioctl,
    .open            = mgcdrv_open,
    .release        = mgcdrv_release,
    .mmap            = mgcdrv_mmap,
    .write            = mgcdrv_write,
    .read            = mgcdrv_read,
};

static mgcdrv_data_t        DrvData;
static mgcdrv_data_t        *pDrv=&DrvData;
static struct               cdev mgcdrv_cdev;
static struct completion    IrqDone;
static spinlock_t irq_lock;
unsigned long lock_flags;
struct pci_dev              *pRootPort = NULL;
struct pci_dev              *pEp = NULL;
char *pDrvBuf = NULL;
u_int64_t ddwBufAdd;
u_int32_t dwDmaDone;
u_int32_t dwDmaMemFail;

/**
 * add device id and device id for memory endpoint and duft endpoints 
 */
 
static struct pci_device_id mgcdrv_pci_device_ids[] = 
{
    { PCI_DEVICE( PCI_VENDOR_ID_MGCDRV, PCI_DEVICE_ID_MGCDRV)},
    { PCI_DEVICE( PCI_VENDOR_ID_MGCDRV, PCI_DEVICE_ID_DUFT_EP)},
    { PCI_DEVICE( PCI_VENDOR_ID_MGCDRV, 0x1029)},
    { 0},
};
/***********************************************************************************/
/* GLOBAL */
/***********************************************************************************/
int mgcdrv_major = DEVMAJOR;
int mgcdrv_minor = 0;
module_param( mgcdrv_major, int, S_IRUGO);
module_param( mgcdrv_minor, int, S_IRUGO);
MODULE_DEVICE_TABLE( pci, mgcdrv_pci_device_ids);

/**
* mgcdrv_irq_handler: irq handler
* @return: IRQ_HANDLED or IRQ_NONE
*/
static irqreturn_t mgcdrv_irq_handler( int      irq,
                                       void *   dev_id,
                                       void *   pContext)
{
	irqreturn_t retval = IRQ_NONE;    
    u_int32_t dwVal;
    if(pDrv->bDuftEp) { /* DUFT Ep */
        /* lock resources */
        spin_lock(&irq_lock);    
        dwVal = readl(pDrv->Bar[pDrv->bBarOfIrqReg].pAdd + pDrv->dwIrqOffset);	
        if(dwVal & pDrv->dwIrqMaskVal) { 
            __INFO("Receive IRQ for DUFT Ep with value %x, mask =%x\n",dwVal,pDrv->dwIrqMaskVal);
            writel(0xFFFFFFFF,pDrv->Bar[pDrv->bBarOfIrqReg].pAdd + pDrv->dwIrqOffset);
            pDrv->dwIrqStsVal = dwVal;
            complete(&IrqDone);
            pDrv->Info.dwIrqCount++;
            retval = IRQ_HANDLED;
        } else {
            pDrv->Info.dwFakeIrqCount++;
            retval = IRQ_NONE;
        }
        /* unlock resources */        
        spin_unlock(&irq_lock);        
		/**
		 * Always inform OS that IRQ is handled
		 * to avoid infinite assertion
		 * */
        return IRQ_HANDLED;
        
    } else {
        dwVal = readl(pDrv->Bar[2].pAdd + MGCDRV_REG_IRQ);	
        if(dwVal & 0x1) { 
            __INFO("Receive IRQ\n");
            writel(dwVal,pDrv->Bar[2].pAdd + MGCDRV_REG_IRQ);
            complete(&IrqDone);
            pDrv->Info.dwIrqCount++;
            return IRQ_HANDLED;
        } else {
            pDrv->Info.dwFakeIrqCount++;
            return IRQ_NONE;
        }
    }
}

/**
* mgcdrv_do_init_irq: init the irq
*/
static void mgcdrv_do_init_irq(void)
{
    if(pDrv->bIrqEnable) {
        init_completion(&IrqDone);
    }
}
static void mgcdrv_do_wait_irq(void)
{
    u_int32_t    dwVal;
    u_int32_t    dwCount = 0;;
    
    __NOTE("Start waiting for operation to complete: use %s\n",(pDrv->bIrqEnable)?"IRQ":"Polling");
    if(pDrv->bIrqEnable) {                     
        wait_for_completion(&IrqDone);;        
        pDrv->Info.dwDmaRdCount++;            
    } else {
        usleep_range(10000, 20000);        
        /* polling for check done */
        do {
            dwCount++;            
            dwVal = readl(pDrv->Bar[2].pAdd + MGCDRV_REG_IRQ);    
            if(dwVal & 0x1) { 
                __INFO("IRQ register is set\n");
                writel(dwVal,pDrv->Bar[2].pAdd + MGCDRV_REG_IRQ);
                pDrv->Info.dwIrqCount++;
                break;
            } else {
                usleep_range(10000, 20000);
            }
            if(dwCount > 10) {
                printk("Error, Wait for long time polling for irq, break\n");
                break;                
            }
        }while(1);
    }
    __NOTE("Finish waiting for operation\n");
};

/**
* mgcdrv_probe: called when the endpoint is detected by system
* @return: 0 for success
*          1 for failure
*/
static int __devinit mgcdrv_probe( struct pci_dev *pdev, 
                                   const struct pci_device_id *ent)
{
    int             ret;
    int             i;
    struct resource *res;
    
    pDrv->bProbe = 0;
    
	__INFO("Start of mgcdrv_probe\n");
    
	if(pdev->vendor == PCI_VENDOR_ID_MGCDRV && pdev->device == 0x1029) {
//if(pdev->vendor == PCI_VENDOR_ID_MGCDRV && pdev->device == PCI_DEVICE_ID_MGCDRV) {
        __INFO("Mentor PCIe Memory Endpoint detected \n");
        pDrv->bMemEp        = 1;
        pDrv->bBarOfIrqReg  = 2 ;      
        pDrv->dwIrqOffset   = MGCDRV_REG_IRQ;        
        pDrv->dwIrqMaskVal  = 0x1;        
    } else if(pdev->vendor == PCI_VENDOR_ID_MGCDRV && pdev->device == PCI_DEVICE_ID_DUFT_EP) {
        __INFO("Mentor PCIe DUFT Endpoint detected \n");
        pDrv->bDuftEp       = 1; 
        pDrv->bBarOfIrqReg  = 0 ;       // DUFT_BAR_MAP_CTRL;
        pDrv->dwIrqOffset   = 0x044;    // DUFT_REG_IRQ_STATUS
        pDrv->dwIrqMaskVal  = 0x1;
    } else { 
		_ERR( "%s: invalid vendor id and device id\n", __FUNCTION__);
        return -ENODEV;    
	};
    pDrv->HwInfo.wVendorId      = pdev->vendor;
    pDrv->HwInfo.wDeviceId      = pdev->device;
    pDrv->HwInfo.ddwDrvBufSize  = DRV_BUF_SIZE ;      
    pDrv->HwInfo.ddwBuf64PhyAdd = (u_int64_t)pDrv->Buf64handle;
    pDrv->HwInfo.ddwBuf32PhyAdd = (u_int64_t)pDrv->Buf32handle;
    pDrv->HwInfo.bDevFunc       = pdev->devfn;
    pDrv->HwInfo.bBusNum        = pdev->bus->number;
    pDrv->HwInfo.wPCIeCapOffset = pdev->pcie_cap;
    //pDrv->HwInfo.bMpsSupported  = pdev->pcie_mpss;
#ifdef CONFIG_PCIEAER    
    //pDrv->HwInfo.wPCIeAerOffset = pdev->aer_cap;
#endif    
            
    ret = pci_enable_device(pdev);
    
    /* Enable bus mastering */
    pci_set_master( pdev );
       
    /* Use BAR 0 & 2*/
	for( i=0; i<6; i++) {
        pDrv->Bar[i].ddwStart   = pci_resource_start( pdev, i);
        pDrv->Bar[i].ddwEnd     = pci_resource_end( pdev, i);
        pDrv->Bar[i].ddwFlags   = pci_resource_flags( pdev, i);
        pDrv->Bar[i].ddwLen     = pci_resource_len(pdev,i);
        if(pDrv->Bar[i].ddwLen) {
            res = request_mem_region( pDrv->Bar[i].ddwStart, pDrv->Bar[i].ddwLen,DRV_NAME);
            if(res == NULL) {
                _ERR("Fail to request_mem_region of BAR#%d\n",i);
                goto CLEAN_UP_RES;                
            }
            
            /* check if enough space for BAR access */            
            /* Update: No need to check for now, dma can be splitted */
            if((pDrv->Bar[i].ddwLen > DRV_BUF_SIZE) && 0) {
                _ERR("The Driver buffer %u is less than Bar%u size=%lu, failed\n",DRV_BUF_SIZE,i,pDrv->Bar[i].ddwLen);
                goto CLEAN_UP_RES;                
            }            
            pDrv->Bar[i].pAdd           = ioremap( pDrv->Bar[i].ddwStart, pDrv->Bar[i].ddwLen);
            /* log the hw info */
            pDrv->HwInfo.aBarSizes[i]   = pDrv->Bar[i].ddwLen;
            pDrv->HwInfo.aIsBarPref[i]  = (pDrv->Bar[i].ddwFlags & IORESOURCE_PREFETCH) ? 1 : 0;
            pDrv->HwInfo.aIsBar64[i]    = (pDrv->Bar[i].ddwFlags & IORESOURCE_MEM_64) ? 1 : 0;
            
            __INFO("Bar[%d]: Add=%p, Len=%lu bytes\n",i,pDrv->Bar[i].pAdd, ( long)pDrv->Bar[i].ddwLen);            
            
            
            /* get next bar if 64 */
            i = (pDrv->Bar[i].ddwFlags & IORESOURCE_MEM_64) ? i+1 : i;            
        }
    }
    
    if(request_irq(pdev->irq, (void *)mgcdrv_irq_handler, IRQF_SHARED, DRV_NAME, pDrv) != 0 ) {
        _ERR("ERROR: Could not install interrupt handler !!!\n");
        goto CLEAN_UP_RES;                
    }
    
	pDrv->bIrqEnable = 1;    
    pRootPort = pdev->bus->self;
    pEp       = pdev;
    
	__INFO("Success to probe the mgcdrv_probe\n");
    
    pDrv->bProbe = 1;

	return 0;
    
CLEAN_UP_RES:
	pci_disable_device(pdev);
    for(i=0;i<6;i++) {
        if(pDrv->Bar[i].pAdd) {
            iounmap( pDrv->Bar[i].pAdd);
            release_mem_region( pDrv->Bar[i].ddwStart, pDrv->Bar[i].ddwLen);
            pDrv->Bar[i].pAdd = NULL;
        }
    } 
    _ERR("Fail to probe the driver for hw, any open will fail\n");    
    return -ENODEV;    
}


/**
* mgcdrv_remove: called when the endpoint is removed from system
* @return: 0 for success
*          1 for failure
*/
static void __devexit mgcdrv_remove( struct pci_dev *pdev)
{
    u_int8_t i;
    
	__DBG("start of mgcdrv_remove\n");
    
    if(!pDrv->bProbe) {
        __INFO("Probe didn't completed, skip remove\n");  
        return ;
    }

	free_irq(pdev->irq, pDrv);

    pci_disable_device( pdev);

    for(i=0;i<6;i++) {
        if(pDrv->Bar[i].pAdd) {
            iounmap( pDrv->Bar[i].pAdd);
            release_mem_region( pDrv->Bar[i].ddwStart, pDrv->Bar[i].ddwLen);
            pDrv->Bar[i].pAdd = NULL;
        }
    }  
    
    __INFO("Remove\n");    
    
    __DBG("end of mgcdrv_remove\n");    
}


/**********************************************************/
/* mgcdrv_pci_driver                                     */
/**********************************************************/
static struct pci_driver mgcdrv_pci_driver = {
    .name        = "mgcdrv",
    .id_table    = mgcdrv_pci_device_ids,
    .probe        = mgcdrv_probe,
    .remove        = __devexit_p( mgcdrv_remove),
};


/**
* mgcdrv_init_module: called when the module is loaded
* @return: 0 for success
*          1 for failure
*/
static int mgcdrv_init_module( void)
{
    int     ret;
    dev_t   dev;
    int     devno;
    
    memset(pDrv,0,sizeof(mgcdrv_data_t));

    __DBG("start of mgcdrv_init_module\n");    
    spin_lock_init(&irq_lock);
    ret = pci_register_driver( &mgcdrv_pci_driver);
    if( ret!=0) {
        return -ENODEV;
    }

    if(mgcdrv_major!=0) {
        dev = MKDEV( mgcdrv_major, mgcdrv_minor);
        ret = register_chrdev_region( dev, 1, DRV_NAME);
    } else {
        ret = alloc_chrdev_region( &dev, mgcdrv_minor, 1, DRV_NAME);
        mgcdrv_major = MAJOR( dev);
    }

    if( ret<0) {
        _ERR("can't get major %d\n", mgcdrv_major);
        return ret;
    }

    /* init cdev */
    devno = MKDEV( mgcdrv_major, mgcdrv_minor);
    cdev_init( &mgcdrv_cdev, &mgcdrv_fops);
    mgcdrv_cdev.owner = THIS_MODULE;
    mgcdrv_cdev.ops = &mgcdrv_fops;

    /* add cdev */
	ret = cdev_add( &mgcdrv_cdev, devno, 1);
	if( ret) {
		_ERR("error cdev_add result=%d\n", ret);
		return -ENODEV;
	}

    if (pEp)
        pDrv->pBuf32  = dma_alloc_coherent(&pEp->dev,DRV_BUF_SIZE,&pDrv->Buf32handle, GFP_KERNEL);
    
    if(!pDrv->pBuf32) {
		printk("Cannot allocate dma buffer below 4G \n");
		return -ENODEV;
    } 
    
	pDrv->pBuf64        = (void *)kmalloc(DRV_BUF_SIZE, GFP_KERNEL | GFP_HIGHUSER);
	pDrv->Buf64handle   = virt_to_bus(pDrv->pBuf64);

    if(!pDrv->pBuf64) {
		printk("Cannot allocate dma buffer Above 4G \n");
		return -ENODEV;
    } 

    __INFO("Install mgcdrv device driver with version %s, major %d\n",MGCDRV_DRIVER_VERSION,mgcdrv_major); 
    __INFO("DMA below 4G (@0x%llx, %u bytes)\n",(u_int64_t)pDrv->Buf32handle,DRV_BUF_SIZE);
    __INFO("DMA above 4G (@0x%llx, %u bytes)\n",(u_int64_t)pDrv->Buf64handle,DRV_BUF_SIZE);
    
    return 0;
}


/**
* mgcdrv_init_module: called when the module is unloaded
* @return: void
*/
static void mgcdrv_cleanup_module( void)
{
    dev_t devno;

    __DBG("start of mgcdrv_cleanup_module\n");    

    /* del cdev */
    cdev_del( &mgcdrv_cdev);

    devno = MKDEV( mgcdrv_major, mgcdrv_minor);
    unregister_chrdev_region( devno, 1);

    pci_unregister_driver( &mgcdrv_pci_driver);
    
    if(pDrv->pBuf32) {
        dma_free_coherent(NULL,DRV_BUF_SIZE,pDrv->pBuf32,pDrv->Buf32handle);        
    }

    if(pDrv->pBuf64)
        kfree(pDrv->pBuf64);
    
    __DBG("end of mgcdrv_cleanup_module\n");        
}
module_init( mgcdrv_init_module);
module_exit( mgcdrv_cleanup_module);


/**
* mgcdrv_open: called when the driver is opened
* @return: void
*/
static int mgcdrv_open( struct inode *pinode, struct file *pfile)
{
    int minor;

    __DBG("start of mgcdrv_open\n");        
      
    minor = iminor( pinode);

    pfile->private_data = NULL;
    
    __DBG("end of mgcdrv_open\n");        
    
    if(!pDrv->bProbe) {
        _ERR("Cannot do open, the probe failed\n");
        return -ENODEV;
    }    

    return 0;
}


/**
* mgcdrv_release: called when the driver is closed
* @return: void
*/
static int mgcdrv_release( struct inode *pinode, struct file *pfile)
{
    int minor;
    int ret;

    __DBG("start of mgcdrv_release\n"); 
      
    minor = iminor( pinode);

    ret = 0;
    
    __DBG("end of mgcdrv_release\n");        
    if(!pDrv->bProbe) {
        _ERR("Cannot do close, the probe failed\n");
        return -ENODEV;
    }
    return ret;
}

/**
* mgcdrv_write: write from user to driver
* @return: void
*/
ssize_t mgcdrv_write(struct file *  filp,
                     const char *   buf,
                     size_t         count,
                     loff_t *       offp )
{
    int status;  
	status = mgc_copy_from_user(pDrv->bUseBuf32 ? (void *)(pDrv->pBuf32 + pDrv->dwBufOffset): (void *)(pDrv->pBuf64 + pDrv->dwBufOffset),
            (const void *)buf, count);
    return status;
}

/**
* mgcdrv_read: read from user to driver
* @return: void
*/
ssize_t mgcdrv_read(struct file *  filp,
                    char *         buf,
                    size_t         count,
                    loff_t *       offp )
{
    int status;
    status = mgc_copy_to_user ((void *)buf,
            pDrv->bUseBuf32 ? (const void *)(pDrv->pBuf32 + pDrv->dwBufOffset): (const void *)(pDrv->pBuf64 + pDrv->dwBufOffset),
            count);
    return status;
}
                        
/**
* mgcdrv_mmap: called when the driver is mapped
* @return: void
*/
int mgcdrv_mmap( struct file * filp,struct vm_area_struct *  vma )
{
    unsigned long      start   = vma->vm_start;
    unsigned long      size    = vma->vm_end - vma->vm_start;
    unsigned long      phys    = 0;
    int                status  = 0;
    
    __DBG("start of mgcdrv_mmap\n");        

    /* vmap is locked */
    vma->vm_flags |=  VM_LOCKED;    
    
    switch(pDrv->bMapRegion) 
    {
        case MGCDRV_MAP_BAR0:  
            __DBG("MGCDRV_MAP_BAR0\n");                
            phys = (unsigned long)pDrv->Bar[0].pAdd;
            vma->vm_flags |= VM_IO;            
            break;
             
        case MGCDRV_MAP_BAR2:
            __DBG("MGCDRV_MAP_BAR2\n");                        
            phys = (unsigned long)pDrv->Bar[2].pAdd;
            vma->vm_flags |= VM_IO;         
            break; 
            
        default:
            printk(KERN_ERR DRV_NAME "invalid map region number %u\n",pDrv->bMapRegion);
            return 1;                   
    };
    
    while (size>0) {
        status = remap_pfn_range( vma, start, phys >> PAGE_SHIFT, PAGE_SIZE, vma->vm_page_prot );
        if (status) {
            _ERR(": ERROR: %d\n", status );
            return status;
        }

        start += PAGE_SIZE;
        phys  += PAGE_SIZE;
        size   = (size < PAGE_SIZE) ? 0 : (size - PAGE_SIZE);
    }

    __DBG("end of mgcdrv_mmap\n");        

    return 0;        
}

/**
* mgcdrv_ioctl: ioctl driver handler
* @return: void
*/
static long mgcdrv_ioctl(struct file *pfile, 
                         unsigned int cmd, 
                         unsigned long arg)
{
	long            lret,status;
    unsigned long   user_payload = arg+sizeof(mgcdrv_cmd_t);
	u_int16_t		wVal;
	u_int64_t	    bus_addr;
    mgcdrv_cmd_t    *pCmd,Cmd;
    struct pci_dev  *pDevice;
    unsigned long   lock_flags;    
	lret = 0;
    pCmd = &Cmd;
    
    __NOTE("start of mgcdrv_ioctl: 0x%x, %s \n",cmd,GET_IOCTL_NAME(cmd));        

    status = mgc_copy_from_user((void *)pCmd, (const void *)arg, sizeof(mgcdrv_cmd_t));
    
    __DBG("pCmd->ddwValue %lu\n",(long unsigned int)pCmd->ddwValue);
    __DBG("pCmd->dwOffset %u\n",pCmd->dwOffset);
    __DBG("pCmd->dwLen    %u\n",pCmd->dwLen);
    __DBG("pCmd->ddwParam %lu\n",(long unsigned int)pCmd->ddwParam);
    
    pDevice = (pCmd->ddwParam) ? pEp : pRootPort;
    switch(cmd) {               
        case MGCDRV_IOCTL_DMA_RD:
            __NOTE("Program DMA for Read \n");
            bus_addr = (pCmd->dwBase) ? (u_int64_t) pDrv->Buf64handle :
                                        (u_int64_t) pDrv->Buf32handle ;            
                                      
            writel((u_int32_t)(bus_addr >>  0 ),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_LO);
            writel((u_int32_t)(bus_addr >>  32),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_HI);
            writel(pCmd->dwLen,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_SIZE);
            __NOTE("Kick DMA RD engine \n");
            mgcdrv_do_init_irq();
            writel(0x4,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_INFO);
            mgcdrv_do_wait_irq();
            __NOTE("Done DMA RD \n");
            break;
               
        case MGCDRV_IOCTL_DMA_WR:
            __NOTE("Program DMA for Write \n");              
            bus_addr = (pCmd->dwBase) ? (u_int64_t) pDrv->Buf64handle :
                                        (u_int64_t) pDrv->Buf32handle ;    
                                        
            writel((u_int32_t)(bus_addr >>  0 ),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_LO);
            writel((u_int32_t)(bus_addr >>  32),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_HI);
            writel(pCmd->dwLen,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_SIZE);
            __NOTE("Kick DMA Wr and wait for IRQ \n");
            mgcdrv_do_init_irq();
            writel(0x4,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_INFO);
            mgcdrv_do_wait_irq();
            __NOTE("Done DMA Wr \n");
            pDrv->Info.dwDmaWrCount++;                        
            break;
            
		case MGCDRV_IOCTL_KICK_WAIT_IRQ:
            init_completion(&IrqDone);           
			__NOTE("Kick Reg and wait IRQ(bar=0x%x, offet=0x%x, val=0x%llx, base=0x%x)\n",
                   pCmd->dwIndex,pCmd->dwOffset,pCmd->ddwValue,pCmd->dwBase);            
                   
            /* set bWaitIrq */
            spin_lock_irqsave(&irq_lock, lock_flags);
            pDrv->dwIrqMaskVal  = pCmd->dwBase;
            pDrv->dwIrqStsVal   = 0;              
            spin_unlock_irqrestore(&irq_lock, lock_flags);
            
            /* if timeout happens, dwBase=1 */
			writel(pCmd->ddwValue,pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset);            
            pCmd->dwIndex    = (wait_for_completion_timeout(&IrqDone,msecs_to_jiffies(MGCRDV_TIMEOUT))) ? 0 : 1;
            pCmd->ddwValue   = pDrv->dwIrqStsVal;
			__NOTE("Finish waiting for IRQ, timeout=%u, irq_status=0x%llx\n",pCmd->dwIndex,pCmd->ddwValue);            
            
            /* clear bWaitIrq */
            spin_lock_irqsave(&irq_lock, lock_flags);
            pDrv->dwIrqMaskVal  = 0;
            pDrv->dwIrqStsVal   = 0;               
            spin_unlock_irqrestore(&irq_lock, lock_flags);
 
            /* copy the IRQ status to app */
            status = mgc_copy_to_user((void *)arg,(const void*)pCmd, sizeof(mgcdrv_cmd_t));            
            
			break;
            
		case MGCDRV_IOCTL_MEM_RD:
            if(pCmd->dwBase == 1) {
                pCmd->ddwValue = readb(pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset );
            } else if (pCmd->dwBase == 2) {
                pCmd->ddwValue = readw(pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset );
            } else if (pCmd->dwBase == 4) {
                pCmd->ddwValue = readl(pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset );
            } else if (pCmd->dwBase == 8) {
                pCmd->ddwValue = readq(pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset );
                __DBG("readq: Bar%u, Offset=0x%x, Val=0x%llx\n",pCmd->dwIndex,pCmd->dwOffset,pCmd->ddwValue);

            }
            pDrv->Info.dwMemRdCount++;
            status = mgc_copy_to_user((void *)arg,(const void*)pCmd, sizeof(mgcdrv_cmd_t));
            break;
            
        case MGCDRV_IOCTL_MEM_WR:
            if(pCmd->dwBase == 1) {
                writeb(pCmd->ddwValue,pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset);
            } else if (pCmd->dwBase == 2) {
                writew(pCmd->ddwValue,pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset);
            } else if (pCmd->dwBase == 4) {
                writel(pCmd->ddwValue,pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset);
            } else if (pCmd->dwBase == 8) {
                writeq(pCmd->ddwValue,pDrv->Bar[pCmd->dwIndex].pAdd + pCmd->dwOffset);
                __DBG("writeq: Bar%u, Offset=0x%x, Val=0x%llx\n",pCmd->dwIndex,pCmd->dwOffset,pCmd->ddwValue);                
            };
            pDrv->Info.dwMemWrCount++;                                                        
            break;
            
        case MGCDRV_IOCTL_CFG_RD:        
            if(pCmd->dwLen == 1) {
                pci_read_config_byte (pDevice,pCmd->dwOffset,(u_int8_t*)&pCmd->ddwValue);
            } else if(pCmd->dwLen == 2) {
                pci_read_config_word (pDevice,pCmd->dwOffset,(u_int16_t*)&pCmd->ddwValue);
            } else if(pCmd->dwLen == 4) {
                pci_read_config_dword(pDevice,pCmd->dwOffset,(u_int32_t*)&pCmd->ddwValue);
            }
            pDrv->Info.dwCfgRdCount++; 
            status = mgc_copy_to_user((void *)arg,(const void*)pCmd, sizeof(mgcdrv_cmd_t));            
            break;
            
        case MGCDRV_IOCTL_CFG_WR:        
            if(pCmd->dwLen == 1) {
                pci_write_config_byte (pDevice,pCmd->dwOffset,pCmd->ddwValue);
            } else if(pCmd->dwLen == 2) {
                pci_write_config_word (pDevice,pCmd->dwOffset,pCmd->ddwValue);
            } else if(pCmd->dwLen == 4) {
                pci_write_config_dword(pDevice,pCmd->dwOffset,pCmd->ddwValue);
            }
            pDrv->Info.dwCfgWrCount++;                                                                                
            break;
            
        case MGCDRV_IOCTL_GET_BAR_SIZE:        
            if((pCmd->dwIndex == 0) || (pCmd->dwIndex == 2)) {
                pCmd->ddwValue = pDrv->Bar[pCmd->dwIndex].ddwLen;
            }; 
            status = mgc_copy_to_user((void *)arg,(const void*)pCmd, sizeof(mgcdrv_cmd_t));                        
            break;
            
        case MGCDRV_IOCTL_SET_DBG:        
            if(pCmd->ddwValue <= 2) {
                pDrv->bDebugLevel = pCmd->ddwValue;
            };            
            break;

        case MGCDRV_IOCTL_GET_BUF_ADD: 
            pCmd->ddwValue = (pCmd->dwBase)? pDrv->Buf64handle : pDrv->Buf32handle;
            status         = mgc_copy_to_user((void *)arg,(const void*)pCmd, sizeof(mgcdrv_cmd_t));                        
            break;
            
        case MGCDRV_IOCTL_SET_MAP:
            pDrv->bMapRegion = pCmd->ddwValue;
            __NOTE("Set Map to %u\n",pDrv->bMapRegion);
            break;

        case MGCDRV_IOCTL_SET_BUF:
            pDrv->bUseBuf32 = (pCmd->dwBase) ? 0 : 1;
            pDrv->dwBufOffset = 0;
            __NOTE("Set Buf to %u\n",pDrv->bUseBuf32);
            break;
            
		case MGCDRV_IOCTL_SET_BUF_W_OFF:
            pDrv->bUseBuf32 = (pCmd->dwBase) ? 0 : 1;
            pDrv->dwBufOffset = pCmd->dwIndex;
            __NOTE("Set Buf to %u with offset %u\n",pDrv->bUseBuf32,pDrv->dwBufOffset);
            break;
            
		case MGCDRV_IOCTL_DISABLE_IRQ:
            pci_read_config_word (pEp,0x4,(u_int16_t*)&wVal);
            wVal |= 0x0400;
            pci_write_config_word (pEp,0x4,wVal);    
            pDrv->bIrqEnable = 0;
            break;
            
        case MGCDRV_IOCTL_ENABLE_IRQ:
            pci_read_config_word (pEp,0x4,(u_int16_t*)&wVal);
            wVal &= 0xFBFF;
            pci_write_config_word (pEp,0x4,wVal);
            pDrv->bIrqEnable = 0;            
            break;

        case MGCDRV_IOCTL_INIT_IRQ: 
            mgcdrv_do_init_irq();
            break;
            
        case MGCDRV_IOCTL_WAIT_IRQ: 
            mgcdrv_do_wait_irq();
            break;	
            
		case MGCDRV_IOCTL_GET_HW_INFO:     
            pDrv->HwInfo.ddwBuf64PhyAdd = (u_int64_t)pDrv->Buf64handle;
            pDrv->HwInfo.ddwBuf32PhyAdd = (u_int64_t)pDrv->Buf32handle;
            pDrv->HwInfo.ddwDrvBufSize  = DRV_BUF_SIZE ;    
            /* copy the payload to user */
            status = mgc_copy_to_user((void *)user_payload,(const void*)&(pDrv->HwInfo), sizeof(mgcdrv_hw_info_t));
            break;			
                       
        case MGCDRV_IOCTL_DMA_WR_MEM_WR_RD:
            __NOTE("Program DMA for Write\n");              
            bus_addr = (pCmd->dwBase) ? (u_int64_t) pDrv->Buf64handle :
                                        (u_int64_t) pDrv->Buf32handle ;    
                                        
            writel((u_int32_t)(bus_addr >>  0 ),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_LO);
            writel((u_int32_t)(bus_addr >>  32),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_HI);
            writel(pCmd->dwLen,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_SIZE);
            __NOTE("Kick DMA Wr\n");
            mgcdrv_do_init_irq();
            writel(0x4,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA1_INFO);
            __NOTE("Kick Mem Wr/Rd\n");
            spin_lock_irqsave(&irq_lock, lock_flags);
            dwDmaDone = 0;
            dwDmaMemFail = 0;
            spin_unlock_irqrestore(&irq_lock, lock_flags);
            async_schedule(async_memory_write_read, NULL);
            __NOTE("wait for DMA Wr IRQ\n");
            mgcdrv_do_wait_irq();
            __NOTE("Done DMA Wr\n");
            pDrv->Info.dwDmaWrCount++;                        
            if(dwDmaMemFail)
                lret = -1;
            break;
            
        case MGCDRV_IOCTL_DMA_RD_MEM_WR_RD:
            __NOTE("Program DMA for Read\n");
            bus_addr = (pCmd->dwBase) ? (u_int64_t) pDrv->Buf64handle :
                                        (u_int64_t) pDrv->Buf32handle ;            
                                      
            writel((u_int32_t)(bus_addr >>  0 ),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_LO);
            writel((u_int32_t)(bus_addr >>  32),pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_HI);
            writel(pCmd->dwLen,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_SIZE);
            __NOTE("Kick DMA RD\n");
            mgcdrv_do_init_irq();
            writel(0x4,pDrv->Bar[2].pAdd + MGCDRV_REG_DMA0_INFO);
            __NOTE("Kick Mem Wr/Rd\n");
            spin_lock_irqsave(&irq_lock, lock_flags);
            dwDmaDone = 0;
            dwDmaMemFail = 0;
            spin_unlock_irqrestore(&irq_lock, lock_flags);
            async_schedule(async_memory_write_read, NULL);
            __NOTE("wait for DMA Rd IRQ\n");
            mgcdrv_do_wait_irq();
            __NOTE("Done DMA RD\n");
            if(dwDmaMemFail)
                lret = -1;
            break;
               
        default:
            lret = -EINVAL;
            break;
    }
    __DBG("end of mgcdrv_ioctl\n");        
    
    return lret;
}

static void async_memory_write_read(void *data, async_cookie_t cookie){
    unsigned int wdata = 0xABCD0123;
    unsigned int rdata = 0;
    while(1){
        writel(wdata,pDrv->Bar[2].pAdd + MGCDRV_REG_ATOMIC_REQ_DWORDS);
        rdata = readl(pDrv->Bar[2].pAdd + MGCDRV_REG_ATOMIC_REQ_DWORDS);
        if(rdata != wdata)
            dwDmaMemFail++;
        spin_lock_irqsave(&irq_lock, lock_flags);
        if(dwDmaDone){
            spin_unlock_irqrestore(&irq_lock, lock_flags);
            break;
        }
        spin_unlock_irqrestore(&irq_lock, lock_flags);
    }
}

MODULE_AUTHOR("Mahmoud Eltahawy <mahmoud_eltahawy@mentor.com>");
MODULE_DESCRIPTION("PCIe Device Driver for Mentor Memory and DUFT Endpoint");
MODULE_LICENSE("GPL");
MODULE_VERSION(MGCDRV_DRIVER_VERSION);
