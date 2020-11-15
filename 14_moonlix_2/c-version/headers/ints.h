/* Список всех обработчиков прерываний */

void Interrupt_Stub(); // Заглушка. Никак не используется. Пустое прерывание без действия.

// @LINK "docs/interrupts.txt"
void Exc00_DE(); 
void Exc01_DB();
void Exc02_NMI();
void Exc03_BP();
void Exc04_OF();
void Exc05_BR();
void Exc06_UD();
void Exc07_NM();
void Exc08_DF();
void Exc09_FPU_seg();
void Exc0A_TS();
void Exc0B_NP();
void Exc0C_SS();
void Exc0D_GP();
void Exc0E_PF();
void Exc0F();
void Exc10_MF();
void Exc11_AC();
void Exc12_MC(); // Machine Device Control
void Exc13_XF(); // SIMD FPU Exception

void IRQ_0();
void IRQ_1();
void IRQ_2();
void IRQ_3();
void IRQ_4();
void IRQ_5();
void IRQ_6();
void IRQ_7();
void IRQ_8();
void IRQ_9();
void IRQ_A();
void IRQ_B();
void IRQ_C();
void IRQ_D();
void IRQ_E();
void IRQ_F();
