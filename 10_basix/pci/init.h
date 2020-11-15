/*
 * PCI регистры конфигурации
 */
 
#define	PCI_CFID	0x00	/* Configuration ID */
#define	PCI_CFCS	0x04	/* Configurtion Command/Status */
#define	PCI_CFRV	0x08	/* Configuration Revision */
#define	PCI_CFLT	0x0c	/* Configuration Latency Timer */
#define	PCI_CBIO	0x10	/* Configuration Base IO Address */
#define	PCI_CFIT	0x3c	/* Configuration Interrupt */
#define	PCI_CFDA	0x40	/* Configuration Driver Area */

#define PHYS_IO_MEM_START	0
#define	PCI_MEM			0
#define	PCI_INTA		0
#define PCI_NSLOTS		22
#define PCI_NBUS		0

#define	PCI_CONF_ADDR_REG	0xcf8
#define	PCI_CONF_FRWD_REG	0xcf8
#define	PCI_CONF_DATA_REG	0xcfc

#define PCI_IO_CONF_START	0xc000

#define MAX_BUS			16
#define MAX_SLOTS		32

uint32_t adapters[ MAX_BUS ][ MAX_SLOTS ];
