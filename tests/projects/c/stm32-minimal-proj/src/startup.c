#include <stdint.h>
#include "reg.h"

/* Bit definition for RCC_CR register */
#define RCC_CR_HSION	((uint32_t) 0x00000001)		/*!< Internal High Speed clock enable */
#define RCC_CR_HSEON	((uint32_t) 0x00010000)		/*!< External High Speed clock enable */
#define RCC_CR_HSERDY	((uint32_t) 0x00020000)		/*!< External High Speed clock ready flag */
#define RCC_CR_CSSON	((uint32_t) 0x00080000)		/*!< Clock Security System enable */

/* Bit definition for RCC_CFGR register */
#define RCC_CFGR_SW		((uint32_t) 0x00000003)	/*!< SW[1:0] bits (System clock Switch) */
#define RCC_CFGR_SW_HSE		((uint32_t) 0x00000001)	/*!< HSE selected as system clock */
#define RCC_CFGR_SWS		((uint32_t) 0x0000000C)	/*!< SWS[1:0] bits (System Clock Switch Status) */
#define RCC_CFGR_HPRE_DIV1	((uint32_t) 0x00000000)	/*!< SYSCLK not divided */
#define RCC_CFGR_PPRE1_DIV1	((uint32_t) 0x00000000)	/*!< HCLK not divided */
#define RCC_CFGR_PPRE2_DIV1	((uint32_t) 0x00000000)	/*!< HCLK not divided */

/* Bit definition for FLASH_ACR register */
#define FLASH_ACR_LATENCY	((uint8_t) 0x03)	/*!< LATENCY[2:0] bits (Latency) */
#define FLASH_ACR_LATENCY_0	((uint8_t) 0x00)	/*!< Bit 0 */
#define FLASH_ACR_PRFTBE	((uint8_t) 0x10)	/*!< Prefetch Buffer Enable */

#define HSE_STARTUP_TIMEOUT	((uint16_t) 0x0500)	/*!< Time out for HSE start up */

/* main program entry point */
extern void main(void);

/* start address for the initialization values of the .data section.
defined in linker script */
extern uint32_t _sidata;
/* start address for the .data section. defined in linker script */
extern uint32_t _sdata;
/* end address for the .data section. defined in linker script */
extern uint32_t _edata;
/* start address for the .bss section. defined in linker script */
extern uint32_t _sbss;
/* end address for the .bss section. defined in linker script */
extern uint32_t _ebss;
/* end address for the stack. defined in linker script */
extern uint32_t _estack;

void rcc_clock_init(void);

void reset_handler(void)
{
	/* Copy the data segment initializers from flash to SRAM */
	uint32_t *idata_begin = &_sidata;
	uint32_t *data_begin = &_sdata;
	uint32_t *data_end = &_edata;
	while (data_begin < data_end) *data_begin++ = *idata_begin++;

	/* Zero fill the bss segment. */
	uint32_t *bss_begin = &_sbss;
	uint32_t *bss_end = &_ebss;
	while (bss_begin < bss_end) *bss_begin++ = 0;

	/* Clock system intitialization */
	rcc_clock_init();

	main();
}

void nmi_handler(void)
{
	while (1);
}

void hardfault_handler(void)
{
	while (1);
}

__attribute((section(".isr_vector")))
uint32_t *isr_vectors[] = {
	(uint32_t *) &_estack,		/* stack pointer */
	(uint32_t *) reset_handler,	/* code entry point */
	(uint32_t *) nmi_handler,	/* NMI handler */
	(uint32_t *) hardfault_handler	/* hard fault handler */
};

void rcc_clock_init(void)
{
	/* Reset the RCC clock configuration to the default reset state(for debug purpose) */
	/* Set HSION bit */
	*RCC_CR |= (uint32_t) 0x00000001;

	/* Reset SW, HPRE, PPRE1, PPRE2, ADCPRE and MCO bits */
	*RCC_CFGR &= (uint32_t) 0xF8FF0000;

	/* Reset HSEON, CSSON and PLLON bits */
	*RCC_CR &= (uint32_t) 0xFEF6FFFF;

	/* Reset HSEBYP bit */
	*RCC_CR &= (uint32_t) 0xFFFBFFFF;

	/* Reset PLLSRC, PLLXTPRE, PLLMUL and USBPRE/OTGFSPRE bits */
	*RCC_CFGR &= (uint32_t) 0xFF80FFFF;

	/* Disable all interrupts and clear pending bits  */
	*RCC_CIR = 0x009F0000;

	/* Configure the System clock frequency, HCLK, PCLK2 and PCLK1 prescalers */
	/* Configure the Flash Latency cycles and enable prefetch buffer */
	volatile uint32_t StartUpCounter = 0, HSEStatus = 0;

	/* SYSCLK, HCLK, PCLK2 and PCLK1 configuration ---------------------------*/
	/* Enable HSE */
	*RCC_CR |= (uint32_t) RCC_CR_HSEON;

	/* Wait till HSE is ready and if Time out is reached exit */
	do {
		HSEStatus = *RCC_CR & RCC_CR_HSERDY;
		StartUpCounter++;
	} while ((HSEStatus == 0) && (StartUpCounter != HSE_STARTUP_TIMEOUT));

	if ((*RCC_CR & RCC_CR_HSERDY) != 0)
		HSEStatus = (uint32_t) 0x01;
	else
		HSEStatus = (uint32_t) 0x00;

	if (HSEStatus == (uint32_t) 0x01) {
		/* Enable Prefetch Buffer */
		*FLASH_ACR |= FLASH_ACR_PRFTBE;

		/* Flash 0 wait state */
		*FLASH_ACR &= (uint32_t) ((uint32_t) ~FLASH_ACR_LATENCY);

		*FLASH_ACR |= (uint32_t) FLASH_ACR_LATENCY_0;

		/* HCLK = SYSCLK */
		*RCC_CFGR |= (uint32_t) RCC_CFGR_HPRE_DIV1;

		/* PCLK2 = HCLK */
		*RCC_CFGR |= (uint32_t) RCC_CFGR_PPRE2_DIV1;

		/* PCLK1 = HCLK */
		*RCC_CFGR |= (uint32_t) RCC_CFGR_PPRE1_DIV1;

		/* Select HSE as system clock source */
		*RCC_CFGR &= (uint32_t) ((uint32_t) ~(RCC_CFGR_SW));
		*RCC_CFGR |= (uint32_t) RCC_CFGR_SW_HSE;

		/* Wait till HSE is used as system clock source */
		while ((*RCC_CFGR & (uint32_t) RCC_CFGR_SWS) != (uint32_t) 0x04);
	} else {
		/* If HSE fails to start-up, the application will have wrong clock
		configuration. User can add here some code to deal with this error */
	}
}
