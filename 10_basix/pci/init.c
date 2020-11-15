#include "init.h"

// Чтение PCI-конфигурации
uint32_t pci_conf_read(uint32_t bus, uint32_t slot, uint32_t offset)
{
	uint32_t mechanism = 0;
	uint32_t data = -1;

	IoWrite32(PCI_CONF_ADDR_REG, (0x80000000 | (bus << 16) | (slot << 11) | offset));
	data = IoRead32(PCI_CONF_DATA_REG);

	if ((data == 0xFFFFFFFF) && (slot < 0x10)) {
        
		IoWrite32(PCI_CONF_FRWD_REG, bus);
		IoWrite32(PCI_CONF_ADDR_REG, 0xF0);
        
		data = IoRead32(PCI_IO_CONF_START | (slot << 8) | offset);

        if (data == 0xFFFFFFFF) {
			return data;
        }
        
		if (!mechanism) {
			mechanism = 1;
        }
        
	} else if (!mechanism) {
		mechanism = 2;
    }

	return data;
}

/*
 * Инициализация PCI на допустимых слотах
 */
 
int pci_init()
{
	uint32_t slot, bus;

	for (bus = 0; bus < MAX_BUS; bus++) {
		for (slot = 0; slot < MAX_SLOTS; slot++) {
			adapters[ bus ][ slot ] = pci_conf_read(bus, slot, PCI_CFID);
        }
    }
	
	return 0;
}
