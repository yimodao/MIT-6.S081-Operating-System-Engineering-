
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	d9478793          	addi	a5,a5,-620 # 80005df0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	f6278793          	addi	a5,a5,-158 # 80001008 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	c4e080e7          	jalr	-946(ra) # 80000d5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	51a080e7          	jalr	1306(ra) # 80002640 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	cc0080e7          	jalr	-832(ra) # 80000e0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	bbc080e7          	jalr	-1092(ra) # 80000d5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	9aa080e7          	jalr	-1622(ra) # 80001b78 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	1aa080e7          	jalr	426(ra) # 80002388 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	3d0080e7          	jalr	976(ra) # 800025ea <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	bd8080e7          	jalr	-1064(ra) # 80000e0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	bc2080e7          	jalr	-1086(ra) # 80000e0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	a7c080e7          	jalr	-1412(ra) # 80000d5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	39a080e7          	jalr	922(ra) # 80002696 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	b02080e7          	jalr	-1278(ra) # 80000e0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	0be080e7          	jalr	190(ra) # 8000250e <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00001097          	auipc	ra,0x1
    80000476:	858080e7          	jalr	-1960(ra) # 80000cca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00241797          	auipc	a5,0x241
    80000486:	52e78793          	addi	a5,a5,1326 # 802419b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b7a50513          	addi	a0,a0,-1158 # 800080f0 <digits+0xb0>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	750080e7          	jalr	1872(ra) # 80000d5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	6a0080e7          	jalr	1696(ra) # 80000e0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	536080e7          	jalr	1334(ra) # 80000cca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	4e0080e7          	jalr	1248(ra) # 80000cca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	508080e7          	jalr	1288(ra) # 80000d0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	576080e7          	jalr	1398(ra) # 80000dae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	c58080e7          	jalr	-936(ra) # 8000250e <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	460080e7          	jalr	1120(ra) # 80000d5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	a38080e7          	jalr	-1480(ra) # 80002388 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	47a080e7          	jalr	1146(ra) # 80000e0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	35a080e7          	jalr	858(ra) # 80000d5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	3fc080e7          	jalr	1020(ra) # 80000e0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <incref>:
    ref_index[n]=1;
    kfree(p);
  }
}
void incref(uint64 pa)
{int n=pa/PGSIZE;
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
    80000a30:	892a                	mv	s2,a0
    80000a32:	00c55493          	srli	s1,a0,0xc
acquire(&kmem.lock);
    80000a36:	00011517          	auipc	a0,0x11
    80000a3a:	efa50513          	addi	a0,a0,-262 # 80011930 <kmem>
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	31c080e7          	jalr	796(ra) # 80000d5a <acquire>
if(pa>PHYSTOP||ref_index[n]<1)
    80000a46:	47c5                	li	a5,17
    80000a48:	07ee                	slli	a5,a5,0x1b
    80000a4a:	0527e363          	bltu	a5,s2,80000a90 <incref+0x6c>
    80000a4e:	2481                	sext.w	s1,s1
    80000a50:	00249713          	slli	a4,s1,0x2
    80000a54:	00011797          	auipc	a5,0x11
    80000a58:	efc78793          	addi	a5,a5,-260 # 80011950 <ref_index>
    80000a5c:	97ba                	add	a5,a5,a4
    80000a5e:	439c                	lw	a5,0(a5)
    80000a60:	02f05863          	blez	a5,80000a90 <incref+0x6c>
  panic("incref");
ref_index[n]+=1;
    80000a64:	048a                	slli	s1,s1,0x2
    80000a66:	00011717          	auipc	a4,0x11
    80000a6a:	eea70713          	addi	a4,a4,-278 # 80011950 <ref_index>
    80000a6e:	94ba                	add	s1,s1,a4
    80000a70:	2785                	addiw	a5,a5,1
    80000a72:	c09c                	sw	a5,0(s1)
release(&kmem.lock);
    80000a74:	00011517          	auipc	a0,0x11
    80000a78:	ebc50513          	addi	a0,a0,-324 # 80011930 <kmem>
    80000a7c:	00000097          	auipc	ra,0x0
    80000a80:	392080e7          	jalr	914(ra) # 80000e0e <release>
}
    80000a84:	60e2                	ld	ra,24(sp)
    80000a86:	6442                	ld	s0,16(sp)
    80000a88:	64a2                	ld	s1,8(sp)
    80000a8a:	6902                	ld	s2,0(sp)
    80000a8c:	6105                	addi	sp,sp,32
    80000a8e:	8082                	ret
  panic("incref");
    80000a90:	00007517          	auipc	a0,0x7
    80000a94:	5d050513          	addi	a0,a0,1488 # 80008060 <digits+0x20>
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	ab0080e7          	jalr	-1360(ra) # 80000548 <panic>

0000000080000aa0 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000aa0:	7179                	addi	sp,sp,-48
    80000aa2:	f406                	sd	ra,40(sp)
    80000aa4:	f022                	sd	s0,32(sp)
    80000aa6:	ec26                	sd	s1,24(sp)
    80000aa8:	e84a                	sd	s2,16(sp)
    80000aaa:	e44e                	sd	s3,8(sp)
    80000aac:	1800                	addi	s0,sp,48
  struct run *r;
  int n;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000aae:	03451793          	slli	a5,a0,0x34
    80000ab2:	efa5                	bnez	a5,80000b2a <kfree+0x8a>
    80000ab4:	84aa                	mv	s1,a0
    80000ab6:	00245797          	auipc	a5,0x245
    80000aba:	54a78793          	addi	a5,a5,1354 # 80246000 <end>
    80000abe:	06f56663          	bltu	a0,a5,80000b2a <kfree+0x8a>
    80000ac2:	47c5                	li	a5,17
    80000ac4:	07ee                	slli	a5,a5,0x1b
    80000ac6:	06f57263          	bgeu	a0,a5,80000b2a <kfree+0x8a>
    panic("kfree");

  n=(uint64)pa/PGSIZE;
    80000aca:	00c55913          	srli	s2,a0,0xc
    80000ace:	2901                	sext.w	s2,s2

  acquire(&kmem.lock);
    80000ad0:	00011517          	auipc	a0,0x11
    80000ad4:	e6050513          	addi	a0,a0,-416 # 80011930 <kmem>
    80000ad8:	00000097          	auipc	ra,0x0
    80000adc:	282080e7          	jalr	642(ra) # 80000d5a <acquire>
  if(ref_index[n]==0)
    80000ae0:	00291713          	slli	a4,s2,0x2
    80000ae4:	00011797          	auipc	a5,0x11
    80000ae8:	e6c78793          	addi	a5,a5,-404 # 80011950 <ref_index>
    80000aec:	97ba                	add	a5,a5,a4
    80000aee:	439c                	lw	a5,0(a5)
    80000af0:	c7a9                	beqz	a5,80000b3a <kfree+0x9a>
    panic("kfree ref");
  ref_index[n]-=1;
    80000af2:	37fd                	addiw	a5,a5,-1
    80000af4:	0007899b          	sext.w	s3,a5
    80000af8:	090a                	slli	s2,s2,0x2
    80000afa:	00011717          	auipc	a4,0x11
    80000afe:	e5670713          	addi	a4,a4,-426 # 80011950 <ref_index>
    80000b02:	993a                	add	s2,s2,a4
    80000b04:	00f92023          	sw	a5,0(s2)
  int tmp=ref_index[n];
  release(&kmem.lock);
    80000b08:	00011517          	auipc	a0,0x11
    80000b0c:	e2850513          	addi	a0,a0,-472 # 80011930 <kmem>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	2fe080e7          	jalr	766(ra) # 80000e0e <release>
  if(tmp>0)
    80000b18:	03305963          	blez	s3,80000b4a <kfree+0xaa>
  r = (struct run*)pa;
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000b1c:	70a2                	ld	ra,40(sp)
    80000b1e:	7402                	ld	s0,32(sp)
    80000b20:	64e2                	ld	s1,24(sp)
    80000b22:	6942                	ld	s2,16(sp)
    80000b24:	69a2                	ld	s3,8(sp)
    80000b26:	6145                	addi	sp,sp,48
    80000b28:	8082                	ret
    panic("kfree");
    80000b2a:	00007517          	auipc	a0,0x7
    80000b2e:	53e50513          	addi	a0,a0,1342 # 80008068 <digits+0x28>
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	a16080e7          	jalr	-1514(ra) # 80000548 <panic>
    panic("kfree ref");
    80000b3a:	00007517          	auipc	a0,0x7
    80000b3e:	53650513          	addi	a0,a0,1334 # 80008070 <digits+0x30>
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	a06080e7          	jalr	-1530(ra) # 80000548 <panic>
  memset(pa, 1, PGSIZE);
    80000b4a:	6605                	lui	a2,0x1
    80000b4c:	4585                	li	a1,1
    80000b4e:	8526                	mv	a0,s1
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	306080e7          	jalr	774(ra) # 80000e56 <memset>
  acquire(&kmem.lock);
    80000b58:	00011917          	auipc	s2,0x11
    80000b5c:	dd890913          	addi	s2,s2,-552 # 80011930 <kmem>
    80000b60:	854a                	mv	a0,s2
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	1f8080e7          	jalr	504(ra) # 80000d5a <acquire>
  r->next = kmem.freelist;
    80000b6a:	01893783          	ld	a5,24(s2)
    80000b6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b74:	854a                	mv	a0,s2
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	298080e7          	jalr	664(ra) # 80000e0e <release>
    80000b7e:	bf79                	j	80000b1c <kfree+0x7c>

0000000080000b80 <freerange>:
{
    80000b80:	7139                	addi	sp,sp,-64
    80000b82:	fc06                	sd	ra,56(sp)
    80000b84:	f822                	sd	s0,48(sp)
    80000b86:	f426                	sd	s1,40(sp)
    80000b88:	f04a                	sd	s2,32(sp)
    80000b8a:	ec4e                	sd	s3,24(sp)
    80000b8c:	e852                	sd	s4,16(sp)
    80000b8e:	e456                	sd	s5,8(sp)
    80000b90:	e05a                	sd	s6,0(sp)
    80000b92:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b94:	6785                	lui	a5,0x1
    80000b96:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b9a:	9526                	add	a0,a0,s1
    80000b9c:	74fd                	lui	s1,0xfffff
    80000b9e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000ba0:	97a6                	add	a5,a5,s1
    80000ba2:	02f5eb63          	bltu	a1,a5,80000bd8 <freerange+0x58>
    80000ba6:	892e                	mv	s2,a1
    ref_index[n]=1;
    80000ba8:	00011b17          	auipc	s6,0x11
    80000bac:	da8b0b13          	addi	s6,s6,-600 # 80011950 <ref_index>
    80000bb0:	4a85                	li	s5,1
    80000bb2:	6a05                	lui	s4,0x1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000bb4:	6989                	lui	s3,0x2
    int n=(uint64)p/PGSIZE;
    80000bb6:	00c4d793          	srli	a5,s1,0xc
    ref_index[n]=1;
    80000bba:	2781                	sext.w	a5,a5
    80000bbc:	078a                	slli	a5,a5,0x2
    80000bbe:	97da                	add	a5,a5,s6
    80000bc0:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000bc4:	8526                	mv	a0,s1
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	eda080e7          	jalr	-294(ra) # 80000aa0 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000bce:	87a6                	mv	a5,s1
    80000bd0:	94d2                	add	s1,s1,s4
    80000bd2:	97ce                	add	a5,a5,s3
    80000bd4:	fef971e3          	bgeu	s2,a5,80000bb6 <freerange+0x36>
}
    80000bd8:	70e2                	ld	ra,56(sp)
    80000bda:	7442                	ld	s0,48(sp)
    80000bdc:	74a2                	ld	s1,40(sp)
    80000bde:	7902                	ld	s2,32(sp)
    80000be0:	69e2                	ld	s3,24(sp)
    80000be2:	6a42                	ld	s4,16(sp)
    80000be4:	6aa2                	ld	s5,8(sp)
    80000be6:	6b02                	ld	s6,0(sp)
    80000be8:	6121                	addi	sp,sp,64
    80000bea:	8082                	ret

0000000080000bec <kinit>:
{
    80000bec:	1141                	addi	sp,sp,-16
    80000bee:	e406                	sd	ra,8(sp)
    80000bf0:	e022                	sd	s0,0(sp)
    80000bf2:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bf4:	00007597          	auipc	a1,0x7
    80000bf8:	48c58593          	addi	a1,a1,1164 # 80008080 <digits+0x40>
    80000bfc:	00011517          	auipc	a0,0x11
    80000c00:	d3450513          	addi	a0,a0,-716 # 80011930 <kmem>
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	0c6080e7          	jalr	198(ra) # 80000cca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000c0c:	45c5                	li	a1,17
    80000c0e:	05ee                	slli	a1,a1,0x1b
    80000c10:	00245517          	auipc	a0,0x245
    80000c14:	3f050513          	addi	a0,a0,1008 # 80246000 <end>
    80000c18:	00000097          	auipc	ra,0x0
    80000c1c:	f68080e7          	jalr	-152(ra) # 80000b80 <freerange>
}
    80000c20:	60a2                	ld	ra,8(sp)
    80000c22:	6402                	ld	s0,0(sp)
    80000c24:	0141                	addi	sp,sp,16
    80000c26:	8082                	ret

0000000080000c28 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c32:	00011497          	auipc	s1,0x11
    80000c36:	cfe48493          	addi	s1,s1,-770 # 80011930 <kmem>
    80000c3a:	8526                	mv	a0,s1
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	11e080e7          	jalr	286(ra) # 80000d5a <acquire>
  r = kmem.freelist;
    80000c44:	6c84                	ld	s1,24(s1)
  if(r)
    80000c46:	c8ad                	beqz	s1,80000cb8 <kalloc+0x90>
    {kmem.freelist = r->next;
    80000c48:	609c                	ld	a5,0(s1)
    80000c4a:	00011717          	auipc	a4,0x11
    80000c4e:	cef73f23          	sd	a5,-770(a4) # 80011948 <kmem+0x18>
    int n=(uint64)r /PGSIZE;
    80000c52:	00c4d793          	srli	a5,s1,0xc
    if(ref_index[n]>0)
    80000c56:	0007871b          	sext.w	a4,a5
    80000c5a:	00271693          	slli	a3,a4,0x2
    80000c5e:	00011717          	auipc	a4,0x11
    80000c62:	cf270713          	addi	a4,a4,-782 # 80011950 <ref_index>
    80000c66:	9736                	add	a4,a4,a3
    80000c68:	4318                	lw	a4,0(a4)
    80000c6a:	02e04f63          	bgtz	a4,80000ca8 <kalloc+0x80>
      panic("kalloc ref");
    ref_index[(uint64)r/PGSIZE]=1;
    80000c6e:	078a                	slli	a5,a5,0x2
    80000c70:	00011717          	auipc	a4,0x11
    80000c74:	ce070713          	addi	a4,a4,-800 # 80011950 <ref_index>
    80000c78:	97ba                	add	a5,a5,a4
    80000c7a:	4705                	li	a4,1
    80000c7c:	c398                	sw	a4,0(a5)
    }
  release(&kmem.lock);
    80000c7e:	00011517          	auipc	a0,0x11
    80000c82:	cb250513          	addi	a0,a0,-846 # 80011930 <kmem>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	188080e7          	jalr	392(ra) # 80000e0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c8e:	6605                	lui	a2,0x1
    80000c90:	4595                	li	a1,5
    80000c92:	8526                	mv	a0,s1
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	1c2080e7          	jalr	450(ra) # 80000e56 <memset>
  return (void*)r;
}
    80000c9c:	8526                	mv	a0,s1
    80000c9e:	60e2                	ld	ra,24(sp)
    80000ca0:	6442                	ld	s0,16(sp)
    80000ca2:	64a2                	ld	s1,8(sp)
    80000ca4:	6105                	addi	sp,sp,32
    80000ca6:	8082                	ret
      panic("kalloc ref");
    80000ca8:	00007517          	auipc	a0,0x7
    80000cac:	3e050513          	addi	a0,a0,992 # 80008088 <digits+0x48>
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	898080e7          	jalr	-1896(ra) # 80000548 <panic>
  release(&kmem.lock);
    80000cb8:	00011517          	auipc	a0,0x11
    80000cbc:	c7850513          	addi	a0,a0,-904 # 80011930 <kmem>
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	14e080e7          	jalr	334(ra) # 80000e0e <release>
  if(r)
    80000cc8:	bfd1                	j	80000c9c <kalloc+0x74>

0000000080000cca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cca:	1141                	addi	sp,sp,-16
    80000ccc:	e422                	sd	s0,8(sp)
    80000cce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cd6:	00053823          	sd	zero,16(a0)
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ce0:	411c                	lw	a5,0(a0)
    80000ce2:	e399                	bnez	a5,80000ce8 <holding+0x8>
    80000ce4:	4501                	li	a0,0
  return r;
}
    80000ce6:	8082                	ret
{
    80000ce8:	1101                	addi	sp,sp,-32
    80000cea:	ec06                	sd	ra,24(sp)
    80000cec:	e822                	sd	s0,16(sp)
    80000cee:	e426                	sd	s1,8(sp)
    80000cf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cf2:	6904                	ld	s1,16(a0)
    80000cf4:	00001097          	auipc	ra,0x1
    80000cf8:	e68080e7          	jalr	-408(ra) # 80001b5c <mycpu>
    80000cfc:	40a48533          	sub	a0,s1,a0
    80000d00:	00153513          	seqz	a0,a0
}
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6105                	addi	sp,sp,32
    80000d0c:	8082                	ret

0000000080000d0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d18:	100024f3          	csrr	s1,sstatus
    80000d1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d26:	00001097          	auipc	ra,0x1
    80000d2a:	e36080e7          	jalr	-458(ra) # 80001b5c <mycpu>
    80000d2e:	5d3c                	lw	a5,120(a0)
    80000d30:	cf89                	beqz	a5,80000d4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d32:	00001097          	auipc	ra,0x1
    80000d36:	e2a080e7          	jalr	-470(ra) # 80001b5c <mycpu>
    80000d3a:	5d3c                	lw	a5,120(a0)
    80000d3c:	2785                	addiw	a5,a5,1
    80000d3e:	dd3c                	sw	a5,120(a0)
}
    80000d40:	60e2                	ld	ra,24(sp)
    80000d42:	6442                	ld	s0,16(sp)
    80000d44:	64a2                	ld	s1,8(sp)
    80000d46:	6105                	addi	sp,sp,32
    80000d48:	8082                	ret
    mycpu()->intena = old;
    80000d4a:	00001097          	auipc	ra,0x1
    80000d4e:	e12080e7          	jalr	-494(ra) # 80001b5c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d52:	8085                	srli	s1,s1,0x1
    80000d54:	8885                	andi	s1,s1,1
    80000d56:	dd64                	sw	s1,124(a0)
    80000d58:	bfe9                	j	80000d32 <push_off+0x24>

0000000080000d5a <acquire>:
{
    80000d5a:	1101                	addi	sp,sp,-32
    80000d5c:	ec06                	sd	ra,24(sp)
    80000d5e:	e822                	sd	s0,16(sp)
    80000d60:	e426                	sd	s1,8(sp)
    80000d62:	1000                	addi	s0,sp,32
    80000d64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	fa8080e7          	jalr	-88(ra) # 80000d0e <push_off>
  if(holding(lk))
    80000d6e:	8526                	mv	a0,s1
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	f70080e7          	jalr	-144(ra) # 80000ce0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d78:	4705                	li	a4,1
  if(holding(lk))
    80000d7a:	e115                	bnez	a0,80000d9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d7c:	87ba                	mv	a5,a4
    80000d7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d82:	2781                	sext.w	a5,a5
    80000d84:	ffe5                	bnez	a5,80000d7c <acquire+0x22>
  __sync_synchronize();
    80000d86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d8a:	00001097          	auipc	ra,0x1
    80000d8e:	dd2080e7          	jalr	-558(ra) # 80001b5c <mycpu>
    80000d92:	e888                	sd	a0,16(s1)
}
    80000d94:	60e2                	ld	ra,24(sp)
    80000d96:	6442                	ld	s0,16(sp)
    80000d98:	64a2                	ld	s1,8(sp)
    80000d9a:	6105                	addi	sp,sp,32
    80000d9c:	8082                	ret
    panic("acquire");
    80000d9e:	00007517          	auipc	a0,0x7
    80000da2:	2fa50513          	addi	a0,a0,762 # 80008098 <digits+0x58>
    80000da6:	fffff097          	auipc	ra,0xfffff
    80000daa:	7a2080e7          	jalr	1954(ra) # 80000548 <panic>

0000000080000dae <pop_off>:

void
pop_off(void)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e406                	sd	ra,8(sp)
    80000db2:	e022                	sd	s0,0(sp)
    80000db4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000db6:	00001097          	auipc	ra,0x1
    80000dba:	da6080e7          	jalr	-602(ra) # 80001b5c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dc4:	e78d                	bnez	a5,80000dee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dc6:	5d3c                	lw	a5,120(a0)
    80000dc8:	02f05b63          	blez	a5,80000dfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dcc:	37fd                	addiw	a5,a5,-1
    80000dce:	0007871b          	sext.w	a4,a5
    80000dd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dd4:	eb09                	bnez	a4,80000de6 <pop_off+0x38>
    80000dd6:	5d7c                	lw	a5,124(a0)
    80000dd8:	c799                	beqz	a5,80000de6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000de2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000de6:	60a2                	ld	ra,8(sp)
    80000de8:	6402                	ld	s0,0(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret
    panic("pop_off - interruptible");
    80000dee:	00007517          	auipc	a0,0x7
    80000df2:	2b250513          	addi	a0,a0,690 # 800080a0 <digits+0x60>
    80000df6:	fffff097          	auipc	ra,0xfffff
    80000dfa:	752080e7          	jalr	1874(ra) # 80000548 <panic>
    panic("pop_off");
    80000dfe:	00007517          	auipc	a0,0x7
    80000e02:	2ba50513          	addi	a0,a0,698 # 800080b8 <digits+0x78>
    80000e06:	fffff097          	auipc	ra,0xfffff
    80000e0a:	742080e7          	jalr	1858(ra) # 80000548 <panic>

0000000080000e0e <release>:
{
    80000e0e:	1101                	addi	sp,sp,-32
    80000e10:	ec06                	sd	ra,24(sp)
    80000e12:	e822                	sd	s0,16(sp)
    80000e14:	e426                	sd	s1,8(sp)
    80000e16:	1000                	addi	s0,sp,32
    80000e18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e1a:	00000097          	auipc	ra,0x0
    80000e1e:	ec6080e7          	jalr	-314(ra) # 80000ce0 <holding>
    80000e22:	c115                	beqz	a0,80000e46 <release+0x38>
  lk->cpu = 0;
    80000e24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e2c:	0f50000f          	fence	iorw,ow
    80000e30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e34:	00000097          	auipc	ra,0x0
    80000e38:	f7a080e7          	jalr	-134(ra) # 80000dae <pop_off>
}
    80000e3c:	60e2                	ld	ra,24(sp)
    80000e3e:	6442                	ld	s0,16(sp)
    80000e40:	64a2                	ld	s1,8(sp)
    80000e42:	6105                	addi	sp,sp,32
    80000e44:	8082                	ret
    panic("release");
    80000e46:	00007517          	auipc	a0,0x7
    80000e4a:	27a50513          	addi	a0,a0,634 # 800080c0 <digits+0x80>
    80000e4e:	fffff097          	auipc	ra,0xfffff
    80000e52:	6fa080e7          	jalr	1786(ra) # 80000548 <panic>

0000000080000e56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e422                	sd	s0,8(sp)
    80000e5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e5c:	ce09                	beqz	a2,80000e76 <memset+0x20>
    80000e5e:	87aa                	mv	a5,a0
    80000e60:	fff6071b          	addiw	a4,a2,-1
    80000e64:	1702                	slli	a4,a4,0x20
    80000e66:	9301                	srli	a4,a4,0x20
    80000e68:	0705                	addi	a4,a4,1
    80000e6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e70:	0785                	addi	a5,a5,1
    80000e72:	fee79de3          	bne	a5,a4,80000e6c <memset+0x16>
  }
  return dst;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e82:	ca05                	beqz	a2,80000eb2 <memcmp+0x36>
    80000e84:	fff6069b          	addiw	a3,a2,-1
    80000e88:	1682                	slli	a3,a3,0x20
    80000e8a:	9281                	srli	a3,a3,0x20
    80000e8c:	0685                	addi	a3,a3,1
    80000e8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e90:	00054783          	lbu	a5,0(a0)
    80000e94:	0005c703          	lbu	a4,0(a1)
    80000e98:	00e79863          	bne	a5,a4,80000ea8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e9c:	0505                	addi	a0,a0,1
    80000e9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ea0:	fed518e3          	bne	a0,a3,80000e90 <memcmp+0x14>
  }

  return 0;
    80000ea4:	4501                	li	a0,0
    80000ea6:	a019                	j	80000eac <memcmp+0x30>
      return *s1 - *s2;
    80000ea8:	40e7853b          	subw	a0,a5,a4
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret
  return 0;
    80000eb2:	4501                	li	a0,0
    80000eb4:	bfe5                	j	80000eac <memcmp+0x30>

0000000080000eb6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eb6:	1141                	addi	sp,sp,-16
    80000eb8:	e422                	sd	s0,8(sp)
    80000eba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ebc:	00a5f963          	bgeu	a1,a0,80000ece <memmove+0x18>
    80000ec0:	02061713          	slli	a4,a2,0x20
    80000ec4:	9301                	srli	a4,a4,0x20
    80000ec6:	00e587b3          	add	a5,a1,a4
    80000eca:	02f56563          	bltu	a0,a5,80000ef4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ece:	fff6069b          	addiw	a3,a2,-1
    80000ed2:	ce11                	beqz	a2,80000eee <memmove+0x38>
    80000ed4:	1682                	slli	a3,a3,0x20
    80000ed6:	9281                	srli	a3,a3,0x20
    80000ed8:	0685                	addi	a3,a3,1
    80000eda:	96ae                	add	a3,a3,a1
    80000edc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000ede:	0585                	addi	a1,a1,1
    80000ee0:	0785                	addi	a5,a5,1
    80000ee2:	fff5c703          	lbu	a4,-1(a1)
    80000ee6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000eea:	fed59ae3          	bne	a1,a3,80000ede <memmove+0x28>

  return dst;
}
    80000eee:	6422                	ld	s0,8(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    d += n;
    80000ef4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000ef6:	fff6069b          	addiw	a3,a2,-1
    80000efa:	da75                	beqz	a2,80000eee <memmove+0x38>
    80000efc:	02069613          	slli	a2,a3,0x20
    80000f00:	9201                	srli	a2,a2,0x20
    80000f02:	fff64613          	not	a2,a2
    80000f06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000f08:	17fd                	addi	a5,a5,-1
    80000f0a:	177d                	addi	a4,a4,-1
    80000f0c:	0007c683          	lbu	a3,0(a5)
    80000f10:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f14:	fec79ae3          	bne	a5,a2,80000f08 <memmove+0x52>
    80000f18:	bfd9                	j	80000eee <memmove+0x38>

0000000080000f1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e406                	sd	ra,8(sp)
    80000f1e:	e022                	sd	s0,0(sp)
    80000f20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	f94080e7          	jalr	-108(ra) # 80000eb6 <memmove>
}
    80000f2a:	60a2                	ld	ra,8(sp)
    80000f2c:	6402                	ld	s0,0(sp)
    80000f2e:	0141                	addi	sp,sp,16
    80000f30:	8082                	ret

0000000080000f32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e422                	sd	s0,8(sp)
    80000f36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f38:	ce11                	beqz	a2,80000f54 <strncmp+0x22>
    80000f3a:	00054783          	lbu	a5,0(a0)
    80000f3e:	cf89                	beqz	a5,80000f58 <strncmp+0x26>
    80000f40:	0005c703          	lbu	a4,0(a1)
    80000f44:	00f71a63          	bne	a4,a5,80000f58 <strncmp+0x26>
    n--, p++, q++;
    80000f48:	367d                	addiw	a2,a2,-1
    80000f4a:	0505                	addi	a0,a0,1
    80000f4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f4e:	f675                	bnez	a2,80000f3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f50:	4501                	li	a0,0
    80000f52:	a809                	j	80000f64 <strncmp+0x32>
    80000f54:	4501                	li	a0,0
    80000f56:	a039                	j	80000f64 <strncmp+0x32>
  if(n == 0)
    80000f58:	ca09                	beqz	a2,80000f6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f5a:	00054503          	lbu	a0,0(a0)
    80000f5e:	0005c783          	lbu	a5,0(a1)
    80000f62:	9d1d                	subw	a0,a0,a5
}
    80000f64:	6422                	ld	s0,8(sp)
    80000f66:	0141                	addi	sp,sp,16
    80000f68:	8082                	ret
    return 0;
    80000f6a:	4501                	li	a0,0
    80000f6c:	bfe5                	j	80000f64 <strncmp+0x32>

0000000080000f6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f6e:	1141                	addi	sp,sp,-16
    80000f70:	e422                	sd	s0,8(sp)
    80000f72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f74:	872a                	mv	a4,a0
    80000f76:	8832                	mv	a6,a2
    80000f78:	367d                	addiw	a2,a2,-1
    80000f7a:	01005963          	blez	a6,80000f8c <strncpy+0x1e>
    80000f7e:	0705                	addi	a4,a4,1
    80000f80:	0005c783          	lbu	a5,0(a1)
    80000f84:	fef70fa3          	sb	a5,-1(a4)
    80000f88:	0585                	addi	a1,a1,1
    80000f8a:	f7f5                	bnez	a5,80000f76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f8c:	00c05d63          	blez	a2,80000fa6 <strncpy+0x38>
    80000f90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f92:	0685                	addi	a3,a3,1
    80000f94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f98:	fff6c793          	not	a5,a3
    80000f9c:	9fb9                	addw	a5,a5,a4
    80000f9e:	010787bb          	addw	a5,a5,a6
    80000fa2:	fef048e3          	bgtz	a5,80000f92 <strncpy+0x24>
  return os;
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fb2:	02c05363          	blez	a2,80000fd8 <safestrcpy+0x2c>
    80000fb6:	fff6069b          	addiw	a3,a2,-1
    80000fba:	1682                	slli	a3,a3,0x20
    80000fbc:	9281                	srli	a3,a3,0x20
    80000fbe:	96ae                	add	a3,a3,a1
    80000fc0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fc2:	00d58963          	beq	a1,a3,80000fd4 <safestrcpy+0x28>
    80000fc6:	0585                	addi	a1,a1,1
    80000fc8:	0785                	addi	a5,a5,1
    80000fca:	fff5c703          	lbu	a4,-1(a1)
    80000fce:	fee78fa3          	sb	a4,-1(a5)
    80000fd2:	fb65                	bnez	a4,80000fc2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fd4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fd8:	6422                	ld	s0,8(sp)
    80000fda:	0141                	addi	sp,sp,16
    80000fdc:	8082                	ret

0000000080000fde <strlen>:

int
strlen(const char *s)
{
    80000fde:	1141                	addi	sp,sp,-16
    80000fe0:	e422                	sd	s0,8(sp)
    80000fe2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fe4:	00054783          	lbu	a5,0(a0)
    80000fe8:	cf91                	beqz	a5,80001004 <strlen+0x26>
    80000fea:	0505                	addi	a0,a0,1
    80000fec:	87aa                	mv	a5,a0
    80000fee:	4685                	li	a3,1
    80000ff0:	9e89                	subw	a3,a3,a0
    80000ff2:	00f6853b          	addw	a0,a3,a5
    80000ff6:	0785                	addi	a5,a5,1
    80000ff8:	fff7c703          	lbu	a4,-1(a5)
    80000ffc:	fb7d                	bnez	a4,80000ff2 <strlen+0x14>
    ;
  return n;
}
    80000ffe:	6422                	ld	s0,8(sp)
    80001000:	0141                	addi	sp,sp,16
    80001002:	8082                	ret
  for(n = 0; s[n]; n++)
    80001004:	4501                	li	a0,0
    80001006:	bfe5                	j	80000ffe <strlen+0x20>

0000000080001008 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001008:	1141                	addi	sp,sp,-16
    8000100a:	e406                	sd	ra,8(sp)
    8000100c:	e022                	sd	s0,0(sp)
    8000100e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001010:	00001097          	auipc	ra,0x1
    80001014:	b3c080e7          	jalr	-1220(ra) # 80001b4c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001018:	00008717          	auipc	a4,0x8
    8000101c:	ff470713          	addi	a4,a4,-12 # 8000900c <started>
  if(cpuid() == 0){
    80001020:	c139                	beqz	a0,80001066 <main+0x5e>
    while(started == 0)
    80001022:	431c                	lw	a5,0(a4)
    80001024:	2781                	sext.w	a5,a5
    80001026:	dff5                	beqz	a5,80001022 <main+0x1a>
      ;
    __sync_synchronize();
    80001028:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000102c:	00001097          	auipc	ra,0x1
    80001030:	b20080e7          	jalr	-1248(ra) # 80001b4c <cpuid>
    80001034:	85aa                	mv	a1,a0
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	0aa50513          	addi	a0,a0,170 # 800080e0 <digits+0xa0>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	554080e7          	jalr	1364(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80001046:	00000097          	auipc	ra,0x0
    8000104a:	0d8080e7          	jalr	216(ra) # 8000111e <kvminithart>
    trapinithart();   // install kernel trap vector
    8000104e:	00001097          	auipc	ra,0x1
    80001052:	788080e7          	jalr	1928(ra) # 800027d6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001056:	00005097          	auipc	ra,0x5
    8000105a:	dda080e7          	jalr	-550(ra) # 80005e30 <plicinithart>
  }

  scheduler();        
    8000105e:	00001097          	auipc	ra,0x1
    80001062:	04a080e7          	jalr	74(ra) # 800020a8 <scheduler>
    consoleinit();
    80001066:	fffff097          	auipc	ra,0xfffff
    8000106a:	3f4080e7          	jalr	1012(ra) # 8000045a <consoleinit>
    printfinit();
    8000106e:	fffff097          	auipc	ra,0xfffff
    80001072:	70a080e7          	jalr	1802(ra) # 80000778 <printfinit>
    printf("\n");
    80001076:	00007517          	auipc	a0,0x7
    8000107a:	07a50513          	addi	a0,a0,122 # 800080f0 <digits+0xb0>
    8000107e:	fffff097          	auipc	ra,0xfffff
    80001082:	514080e7          	jalr	1300(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80001086:	00007517          	auipc	a0,0x7
    8000108a:	04250513          	addi	a0,a0,66 # 800080c8 <digits+0x88>
    8000108e:	fffff097          	auipc	ra,0xfffff
    80001092:	504080e7          	jalr	1284(ra) # 80000592 <printf>
    printf("\n");
    80001096:	00007517          	auipc	a0,0x7
    8000109a:	05a50513          	addi	a0,a0,90 # 800080f0 <digits+0xb0>
    8000109e:	fffff097          	auipc	ra,0xfffff
    800010a2:	4f4080e7          	jalr	1268(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	b46080e7          	jalr	-1210(ra) # 80000bec <kinit>
    kvminit();       // create kernel page table
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	2a0080e7          	jalr	672(ra) # 8000134e <kvminit>
    kvminithart();   // turn on paging
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	068080e7          	jalr	104(ra) # 8000111e <kvminithart>
    procinit();      // process table
    800010be:	00001097          	auipc	ra,0x1
    800010c2:	9be080e7          	jalr	-1602(ra) # 80001a7c <procinit>
    trapinit();      // trap vectors
    800010c6:	00001097          	auipc	ra,0x1
    800010ca:	6e8080e7          	jalr	1768(ra) # 800027ae <trapinit>
    trapinithart();  // install kernel trap vector
    800010ce:	00001097          	auipc	ra,0x1
    800010d2:	708080e7          	jalr	1800(ra) # 800027d6 <trapinithart>
    plicinit();      // set up interrupt controller
    800010d6:	00005097          	auipc	ra,0x5
    800010da:	d44080e7          	jalr	-700(ra) # 80005e1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010de:	00005097          	auipc	ra,0x5
    800010e2:	d52080e7          	jalr	-686(ra) # 80005e30 <plicinithart>
    binit();         // buffer cache
    800010e6:	00002097          	auipc	ra,0x2
    800010ea:	ef2080e7          	jalr	-270(ra) # 80002fd8 <binit>
    iinit();         // inode cache
    800010ee:	00002097          	auipc	ra,0x2
    800010f2:	582080e7          	jalr	1410(ra) # 80003670 <iinit>
    fileinit();      // file table
    800010f6:	00003097          	auipc	ra,0x3
    800010fa:	520080e7          	jalr	1312(ra) # 80004616 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010fe:	00005097          	auipc	ra,0x5
    80001102:	e3a080e7          	jalr	-454(ra) # 80005f38 <virtio_disk_init>
    userinit();      // first user process
    80001106:	00001097          	auipc	ra,0x1
    8000110a:	d3c080e7          	jalr	-708(ra) # 80001e42 <userinit>
    __sync_synchronize();
    8000110e:	0ff0000f          	fence
    started = 1;
    80001112:	4785                	li	a5,1
    80001114:	00008717          	auipc	a4,0x8
    80001118:	eef72c23          	sw	a5,-264(a4) # 8000900c <started>
    8000111c:	b789                	j	8000105e <main+0x56>

000000008000111e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000111e:	1141                	addi	sp,sp,-16
    80001120:	e422                	sd	s0,8(sp)
    80001122:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001124:	00008797          	auipc	a5,0x8
    80001128:	eec7b783          	ld	a5,-276(a5) # 80009010 <kernel_pagetable>
    8000112c:	83b1                	srli	a5,a5,0xc
    8000112e:	577d                	li	a4,-1
    80001130:	177e                	slli	a4,a4,0x3f
    80001132:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001134:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001138:	12000073          	sfence.vma
  sfence_vma();
}
    8000113c:	6422                	ld	s0,8(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret

0000000080001142 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001142:	7139                	addi	sp,sp,-64
    80001144:	fc06                	sd	ra,56(sp)
    80001146:	f822                	sd	s0,48(sp)
    80001148:	f426                	sd	s1,40(sp)
    8000114a:	f04a                	sd	s2,32(sp)
    8000114c:	ec4e                	sd	s3,24(sp)
    8000114e:	e852                	sd	s4,16(sp)
    80001150:	e456                	sd	s5,8(sp)
    80001152:	e05a                	sd	s6,0(sp)
    80001154:	0080                	addi	s0,sp,64
    80001156:	84aa                	mv	s1,a0
    80001158:	89ae                	mv	s3,a1
    8000115a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000115c:	57fd                	li	a5,-1
    8000115e:	83e9                	srli	a5,a5,0x1a
    80001160:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001162:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001164:	04b7f263          	bgeu	a5,a1,800011a8 <walk+0x66>
    panic("walk");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f9050513          	addi	a0,a0,-112 # 800080f8 <digits+0xb8>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001178:	060a8663          	beqz	s5,800011e4 <walk+0xa2>
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	aac080e7          	jalr	-1364(ra) # 80000c28 <kalloc>
    80001184:	84aa                	mv	s1,a0
    80001186:	c529                	beqz	a0,800011d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001188:	6605                	lui	a2,0x1
    8000118a:	4581                	li	a1,0
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	cca080e7          	jalr	-822(ra) # 80000e56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001194:	00c4d793          	srli	a5,s1,0xc
    80001198:	07aa                	slli	a5,a5,0xa
    8000119a:	0017e793          	ori	a5,a5,1
    8000119e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011a2:	3a5d                	addiw	s4,s4,-9
    800011a4:	036a0063          	beq	s4,s6,800011c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011a8:	0149d933          	srl	s2,s3,s4
    800011ac:	1ff97913          	andi	s2,s2,511
    800011b0:	090e                	slli	s2,s2,0x3
    800011b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011b4:	00093483          	ld	s1,0(s2)
    800011b8:	0014f793          	andi	a5,s1,1
    800011bc:	dfd5                	beqz	a5,80001178 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011be:	80a9                	srli	s1,s1,0xa
    800011c0:	04b2                	slli	s1,s1,0xc
    800011c2:	b7c5                	j	800011a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011c4:	00c9d513          	srli	a0,s3,0xc
    800011c8:	1ff57513          	andi	a0,a0,511
    800011cc:	050e                	slli	a0,a0,0x3
    800011ce:	9526                	add	a0,a0,s1
}
    800011d0:	70e2                	ld	ra,56(sp)
    800011d2:	7442                	ld	s0,48(sp)
    800011d4:	74a2                	ld	s1,40(sp)
    800011d6:	7902                	ld	s2,32(sp)
    800011d8:	69e2                	ld	s3,24(sp)
    800011da:	6a42                	ld	s4,16(sp)
    800011dc:	6aa2                	ld	s5,8(sp)
    800011de:	6b02                	ld	s6,0(sp)
    800011e0:	6121                	addi	sp,sp,64
    800011e2:	8082                	ret
        return 0;
    800011e4:	4501                	li	a0,0
    800011e6:	b7ed                	j	800011d0 <walk+0x8e>

00000000800011e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011e8:	57fd                	li	a5,-1
    800011ea:	83e9                	srli	a5,a5,0x1a
    800011ec:	00b7f463          	bgeu	a5,a1,800011f4 <walkaddr+0xc>
    return 0;
    800011f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011f2:	8082                	ret
{
    800011f4:	1141                	addi	sp,sp,-16
    800011f6:	e406                	sd	ra,8(sp)
    800011f8:	e022                	sd	s0,0(sp)
    800011fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011fc:	4601                	li	a2,0
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f44080e7          	jalr	-188(ra) # 80001142 <walk>
  if(pte == 0)
    80001206:	c105                	beqz	a0,80001226 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001208:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000120a:	0117f693          	andi	a3,a5,17
    8000120e:	4745                	li	a4,17
    return 0;
    80001210:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001212:	00e68663          	beq	a3,a4,8000121e <walkaddr+0x36>
}
    80001216:	60a2                	ld	ra,8(sp)
    80001218:	6402                	ld	s0,0(sp)
    8000121a:	0141                	addi	sp,sp,16
    8000121c:	8082                	ret
  pa = PTE2PA(*pte);
    8000121e:	00a7d513          	srli	a0,a5,0xa
    80001222:	0532                	slli	a0,a0,0xc
  return pa;
    80001224:	bfcd                	j	80001216 <walkaddr+0x2e>
    return 0;
    80001226:	4501                	li	a0,0
    80001228:	b7fd                	j	80001216 <walkaddr+0x2e>

000000008000122a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000122a:	1101                	addi	sp,sp,-32
    8000122c:	ec06                	sd	ra,24(sp)
    8000122e:	e822                	sd	s0,16(sp)
    80001230:	e426                	sd	s1,8(sp)
    80001232:	1000                	addi	s0,sp,32
    80001234:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001236:	1552                	slli	a0,a0,0x34
    80001238:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000123c:	4601                	li	a2,0
    8000123e:	00008517          	auipc	a0,0x8
    80001242:	dd253503          	ld	a0,-558(a0) # 80009010 <kernel_pagetable>
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	efc080e7          	jalr	-260(ra) # 80001142 <walk>
  if(pte == 0)
    8000124e:	cd09                	beqz	a0,80001268 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001250:	6108                	ld	a0,0(a0)
    80001252:	00157793          	andi	a5,a0,1
    80001256:	c38d                	beqz	a5,80001278 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001258:	8129                	srli	a0,a0,0xa
    8000125a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000125c:	9526                	add	a0,a0,s1
    8000125e:	60e2                	ld	ra,24(sp)
    80001260:	6442                	ld	s0,16(sp)
    80001262:	64a2                	ld	s1,8(sp)
    80001264:	6105                	addi	sp,sp,32
    80001266:	8082                	ret
    panic("kvmpa");
    80001268:	00007517          	auipc	a0,0x7
    8000126c:	e9850513          	addi	a0,a0,-360 # 80008100 <digits+0xc0>
    80001270:	fffff097          	auipc	ra,0xfffff
    80001274:	2d8080e7          	jalr	728(ra) # 80000548 <panic>
    panic("kvmpa");
    80001278:	00007517          	auipc	a0,0x7
    8000127c:	e8850513          	addi	a0,a0,-376 # 80008100 <digits+0xc0>
    80001280:	fffff097          	auipc	ra,0xfffff
    80001284:	2c8080e7          	jalr	712(ra) # 80000548 <panic>

0000000080001288 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001288:	715d                	addi	sp,sp,-80
    8000128a:	e486                	sd	ra,72(sp)
    8000128c:	e0a2                	sd	s0,64(sp)
    8000128e:	fc26                	sd	s1,56(sp)
    80001290:	f84a                	sd	s2,48(sp)
    80001292:	f44e                	sd	s3,40(sp)
    80001294:	f052                	sd	s4,32(sp)
    80001296:	ec56                	sd	s5,24(sp)
    80001298:	e85a                	sd	s6,16(sp)
    8000129a:	e45e                	sd	s7,8(sp)
    8000129c:	0880                	addi	s0,sp,80
    8000129e:	8aaa                	mv	s5,a0
    800012a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800012a2:	777d                	lui	a4,0xfffff
    800012a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012a8:	167d                	addi	a2,a2,-1
    800012aa:	00b609b3          	add	s3,a2,a1
    800012ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012b2:	893e                	mv	s2,a5
    800012b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012b8:	6b85                	lui	s7,0x1
    800012ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012be:	4605                	li	a2,1
    800012c0:	85ca                	mv	a1,s2
    800012c2:	8556                	mv	a0,s5
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	e7e080e7          	jalr	-386(ra) # 80001142 <walk>
    800012cc:	c51d                	beqz	a0,800012fa <mappages+0x72>
    if(*pte & PTE_V)
    800012ce:	611c                	ld	a5,0(a0)
    800012d0:	8b85                	andi	a5,a5,1
    800012d2:	ef81                	bnez	a5,800012ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012d4:	80b1                	srli	s1,s1,0xc
    800012d6:	04aa                	slli	s1,s1,0xa
    800012d8:	0164e4b3          	or	s1,s1,s6
    800012dc:	0014e493          	ori	s1,s1,1
    800012e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800012e2:	03390863          	beq	s2,s3,80001312 <mappages+0x8a>
    a += PGSIZE;
    800012e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012e8:	bfc9                	j	800012ba <mappages+0x32>
      panic("remap");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e1e50513          	addi	a0,a0,-482 # 80008108 <digits+0xc8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	256080e7          	jalr	598(ra) # 80000548 <panic>
      return -1;
    800012fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012fc:	60a6                	ld	ra,72(sp)
    800012fe:	6406                	ld	s0,64(sp)
    80001300:	74e2                	ld	s1,56(sp)
    80001302:	7942                	ld	s2,48(sp)
    80001304:	79a2                	ld	s3,40(sp)
    80001306:	7a02                	ld	s4,32(sp)
    80001308:	6ae2                	ld	s5,24(sp)
    8000130a:	6b42                	ld	s6,16(sp)
    8000130c:	6ba2                	ld	s7,8(sp)
    8000130e:	6161                	addi	sp,sp,80
    80001310:	8082                	ret
  return 0;
    80001312:	4501                	li	a0,0
    80001314:	b7e5                	j	800012fc <mappages+0x74>

0000000080001316 <kvmmap>:
{
    80001316:	1141                	addi	sp,sp,-16
    80001318:	e406                	sd	ra,8(sp)
    8000131a:	e022                	sd	s0,0(sp)
    8000131c:	0800                	addi	s0,sp,16
    8000131e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001320:	86ae                	mv	a3,a1
    80001322:	85aa                	mv	a1,a0
    80001324:	00008517          	auipc	a0,0x8
    80001328:	cec53503          	ld	a0,-788(a0) # 80009010 <kernel_pagetable>
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	f5c080e7          	jalr	-164(ra) # 80001288 <mappages>
    80001334:	e509                	bnez	a0,8000133e <kvmmap+0x28>
}
    80001336:	60a2                	ld	ra,8(sp)
    80001338:	6402                	ld	s0,0(sp)
    8000133a:	0141                	addi	sp,sp,16
    8000133c:	8082                	ret
    panic("kvmmap");
    8000133e:	00007517          	auipc	a0,0x7
    80001342:	dd250513          	addi	a0,a0,-558 # 80008110 <digits+0xd0>
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	202080e7          	jalr	514(ra) # 80000548 <panic>

000000008000134e <kvminit>:
{
    8000134e:	1101                	addi	sp,sp,-32
    80001350:	ec06                	sd	ra,24(sp)
    80001352:	e822                	sd	s0,16(sp)
    80001354:	e426                	sd	s1,8(sp)
    80001356:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	8d0080e7          	jalr	-1840(ra) # 80000c28 <kalloc>
    80001360:	00008797          	auipc	a5,0x8
    80001364:	caa7b823          	sd	a0,-848(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001368:	6605                	lui	a2,0x1
    8000136a:	4581                	li	a1,0
    8000136c:	00000097          	auipc	ra,0x0
    80001370:	aea080e7          	jalr	-1302(ra) # 80000e56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001374:	4699                	li	a3,6
    80001376:	6605                	lui	a2,0x1
    80001378:	100005b7          	lui	a1,0x10000
    8000137c:	10000537          	lui	a0,0x10000
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f96080e7          	jalr	-106(ra) # 80001316 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001388:	4699                	li	a3,6
    8000138a:	6605                	lui	a2,0x1
    8000138c:	100015b7          	lui	a1,0x10001
    80001390:	10001537          	lui	a0,0x10001
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f82080e7          	jalr	-126(ra) # 80001316 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000139c:	4699                	li	a3,6
    8000139e:	6641                	lui	a2,0x10
    800013a0:	020005b7          	lui	a1,0x2000
    800013a4:	02000537          	lui	a0,0x2000
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	f6e080e7          	jalr	-146(ra) # 80001316 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013b0:	4699                	li	a3,6
    800013b2:	00400637          	lui	a2,0x400
    800013b6:	0c0005b7          	lui	a1,0xc000
    800013ba:	0c000537          	lui	a0,0xc000
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	f58080e7          	jalr	-168(ra) # 80001316 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013c6:	00007497          	auipc	s1,0x7
    800013ca:	c3a48493          	addi	s1,s1,-966 # 80008000 <etext>
    800013ce:	46a9                	li	a3,10
    800013d0:	80007617          	auipc	a2,0x80007
    800013d4:	c3060613          	addi	a2,a2,-976 # 8000 <_entry-0x7fff8000>
    800013d8:	4585                	li	a1,1
    800013da:	05fe                	slli	a1,a1,0x1f
    800013dc:	852e                	mv	a0,a1
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	f38080e7          	jalr	-200(ra) # 80001316 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013e6:	4699                	li	a3,6
    800013e8:	4645                	li	a2,17
    800013ea:	066e                	slli	a2,a2,0x1b
    800013ec:	8e05                	sub	a2,a2,s1
    800013ee:	85a6                	mv	a1,s1
    800013f0:	8526                	mv	a0,s1
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	f24080e7          	jalr	-220(ra) # 80001316 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013fa:	46a9                	li	a3,10
    800013fc:	6605                	lui	a2,0x1
    800013fe:	00006597          	auipc	a1,0x6
    80001402:	c0258593          	addi	a1,a1,-1022 # 80007000 <_trampoline>
    80001406:	04000537          	lui	a0,0x4000
    8000140a:	157d                	addi	a0,a0,-1
    8000140c:	0532                	slli	a0,a0,0xc
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	f08080e7          	jalr	-248(ra) # 80001316 <kvmmap>
}
    80001416:	60e2                	ld	ra,24(sp)
    80001418:	6442                	ld	s0,16(sp)
    8000141a:	64a2                	ld	s1,8(sp)
    8000141c:	6105                	addi	sp,sp,32
    8000141e:	8082                	ret

0000000080001420 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001420:	715d                	addi	sp,sp,-80
    80001422:	e486                	sd	ra,72(sp)
    80001424:	e0a2                	sd	s0,64(sp)
    80001426:	fc26                	sd	s1,56(sp)
    80001428:	f84a                	sd	s2,48(sp)
    8000142a:	f44e                	sd	s3,40(sp)
    8000142c:	f052                	sd	s4,32(sp)
    8000142e:	ec56                	sd	s5,24(sp)
    80001430:	e85a                	sd	s6,16(sp)
    80001432:	e45e                	sd	s7,8(sp)
    80001434:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001436:	03459793          	slli	a5,a1,0x34
    8000143a:	e795                	bnez	a5,80001466 <uvmunmap+0x46>
    8000143c:	8a2a                	mv	s4,a0
    8000143e:	892e                	mv	s2,a1
    80001440:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001442:	0632                	slli	a2,a2,0xc
    80001444:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001448:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000144a:	6b05                	lui	s6,0x1
    8000144c:	0735e863          	bltu	a1,s3,800014bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001450:	60a6                	ld	ra,72(sp)
    80001452:	6406                	ld	s0,64(sp)
    80001454:	74e2                	ld	s1,56(sp)
    80001456:	7942                	ld	s2,48(sp)
    80001458:	79a2                	ld	s3,40(sp)
    8000145a:	7a02                	ld	s4,32(sp)
    8000145c:	6ae2                	ld	s5,24(sp)
    8000145e:	6b42                	ld	s6,16(sp)
    80001460:	6ba2                	ld	s7,8(sp)
    80001462:	6161                	addi	sp,sp,80
    80001464:	8082                	ret
    panic("uvmunmap: not aligned");
    80001466:	00007517          	auipc	a0,0x7
    8000146a:	cb250513          	addi	a0,a0,-846 # 80008118 <digits+0xd8>
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	0da080e7          	jalr	218(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001476:	00007517          	auipc	a0,0x7
    8000147a:	cba50513          	addi	a0,a0,-838 # 80008130 <digits+0xf0>
    8000147e:	fffff097          	auipc	ra,0xfffff
    80001482:	0ca080e7          	jalr	202(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001486:	00007517          	auipc	a0,0x7
    8000148a:	cba50513          	addi	a0,a0,-838 # 80008140 <digits+0x100>
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	0ba080e7          	jalr	186(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001496:	00007517          	auipc	a0,0x7
    8000149a:	cc250513          	addi	a0,a0,-830 # 80008158 <digits+0x118>
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	0aa080e7          	jalr	170(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800014a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014a8:	0532                	slli	a0,a0,0xc
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	5f6080e7          	jalr	1526(ra) # 80000aa0 <kfree>
    *pte = 0;
    800014b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014b6:	995a                	add	s2,s2,s6
    800014b8:	f9397ce3          	bgeu	s2,s3,80001450 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014bc:	4601                	li	a2,0
    800014be:	85ca                	mv	a1,s2
    800014c0:	8552                	mv	a0,s4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	c80080e7          	jalr	-896(ra) # 80001142 <walk>
    800014ca:	84aa                	mv	s1,a0
    800014cc:	d54d                	beqz	a0,80001476 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014ce:	6108                	ld	a0,0(a0)
    800014d0:	00157793          	andi	a5,a0,1
    800014d4:	dbcd                	beqz	a5,80001486 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014d6:	3ff57793          	andi	a5,a0,1023
    800014da:	fb778ee3          	beq	a5,s7,80001496 <uvmunmap+0x76>
    if(do_free){
    800014de:	fc0a8ae3          	beqz	s5,800014b2 <uvmunmap+0x92>
    800014e2:	b7d1                	j	800014a6 <uvmunmap+0x86>

00000000800014e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014e4:	1101                	addi	sp,sp,-32
    800014e6:	ec06                	sd	ra,24(sp)
    800014e8:	e822                	sd	s0,16(sp)
    800014ea:	e426                	sd	s1,8(sp)
    800014ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014ee:	fffff097          	auipc	ra,0xfffff
    800014f2:	73a080e7          	jalr	1850(ra) # 80000c28 <kalloc>
    800014f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014f8:	c519                	beqz	a0,80001506 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014fa:	6605                	lui	a2,0x1
    800014fc:	4581                	li	a1,0
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	958080e7          	jalr	-1704(ra) # 80000e56 <memset>
  return pagetable;
}
    80001506:	8526                	mv	a0,s1
    80001508:	60e2                	ld	ra,24(sp)
    8000150a:	6442                	ld	s0,16(sp)
    8000150c:	64a2                	ld	s1,8(sp)
    8000150e:	6105                	addi	sp,sp,32
    80001510:	8082                	ret

0000000080001512 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001512:	7179                	addi	sp,sp,-48
    80001514:	f406                	sd	ra,40(sp)
    80001516:	f022                	sd	s0,32(sp)
    80001518:	ec26                	sd	s1,24(sp)
    8000151a:	e84a                	sd	s2,16(sp)
    8000151c:	e44e                	sd	s3,8(sp)
    8000151e:	e052                	sd	s4,0(sp)
    80001520:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001522:	6785                	lui	a5,0x1
    80001524:	04f67863          	bgeu	a2,a5,80001574 <uvminit+0x62>
    80001528:	8a2a                	mv	s4,a0
    8000152a:	89ae                	mv	s3,a1
    8000152c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	6fa080e7          	jalr	1786(ra) # 80000c28 <kalloc>
    80001536:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001538:	6605                	lui	a2,0x1
    8000153a:	4581                	li	a1,0
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	91a080e7          	jalr	-1766(ra) # 80000e56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001544:	4779                	li	a4,30
    80001546:	86ca                	mv	a3,s2
    80001548:	6605                	lui	a2,0x1
    8000154a:	4581                	li	a1,0
    8000154c:	8552                	mv	a0,s4
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	d3a080e7          	jalr	-710(ra) # 80001288 <mappages>
  memmove(mem, src, sz);
    80001556:	8626                	mv	a2,s1
    80001558:	85ce                	mv	a1,s3
    8000155a:	854a                	mv	a0,s2
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	95a080e7          	jalr	-1702(ra) # 80000eb6 <memmove>
}
    80001564:	70a2                	ld	ra,40(sp)
    80001566:	7402                	ld	s0,32(sp)
    80001568:	64e2                	ld	s1,24(sp)
    8000156a:	6942                	ld	s2,16(sp)
    8000156c:	69a2                	ld	s3,8(sp)
    8000156e:	6a02                	ld	s4,0(sp)
    80001570:	6145                	addi	sp,sp,48
    80001572:	8082                	ret
    panic("inituvm: more than a page");
    80001574:	00007517          	auipc	a0,0x7
    80001578:	bfc50513          	addi	a0,a0,-1028 # 80008170 <digits+0x130>
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>

0000000080001584 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001584:	1101                	addi	sp,sp,-32
    80001586:	ec06                	sd	ra,24(sp)
    80001588:	e822                	sd	s0,16(sp)
    8000158a:	e426                	sd	s1,8(sp)
    8000158c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000158e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001590:	00b67d63          	bgeu	a2,a1,800015aa <uvmdealloc+0x26>
    80001594:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001596:	6785                	lui	a5,0x1
    80001598:	17fd                	addi	a5,a5,-1
    8000159a:	00f60733          	add	a4,a2,a5
    8000159e:	767d                	lui	a2,0xfffff
    800015a0:	8f71                	and	a4,a4,a2
    800015a2:	97ae                	add	a5,a5,a1
    800015a4:	8ff1                	and	a5,a5,a2
    800015a6:	00f76863          	bltu	a4,a5,800015b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015aa:	8526                	mv	a0,s1
    800015ac:	60e2                	ld	ra,24(sp)
    800015ae:	6442                	ld	s0,16(sp)
    800015b0:	64a2                	ld	s1,8(sp)
    800015b2:	6105                	addi	sp,sp,32
    800015b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015b6:	8f99                	sub	a5,a5,a4
    800015b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015ba:	4685                	li	a3,1
    800015bc:	0007861b          	sext.w	a2,a5
    800015c0:	85ba                	mv	a1,a4
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	e5e080e7          	jalr	-418(ra) # 80001420 <uvmunmap>
    800015ca:	b7c5                	j	800015aa <uvmdealloc+0x26>

00000000800015cc <uvmalloc>:
  if(newsz < oldsz)
    800015cc:	0ab66163          	bltu	a2,a1,8000166e <uvmalloc+0xa2>
{
    800015d0:	7139                	addi	sp,sp,-64
    800015d2:	fc06                	sd	ra,56(sp)
    800015d4:	f822                	sd	s0,48(sp)
    800015d6:	f426                	sd	s1,40(sp)
    800015d8:	f04a                	sd	s2,32(sp)
    800015da:	ec4e                	sd	s3,24(sp)
    800015dc:	e852                	sd	s4,16(sp)
    800015de:	e456                	sd	s5,8(sp)
    800015e0:	0080                	addi	s0,sp,64
    800015e2:	8aaa                	mv	s5,a0
    800015e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015e6:	6985                	lui	s3,0x1
    800015e8:	19fd                	addi	s3,s3,-1
    800015ea:	95ce                	add	a1,a1,s3
    800015ec:	79fd                	lui	s3,0xfffff
    800015ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015f2:	08c9f063          	bgeu	s3,a2,80001672 <uvmalloc+0xa6>
    800015f6:	894e                	mv	s2,s3
    mem = kalloc();
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	630080e7          	jalr	1584(ra) # 80000c28 <kalloc>
    80001600:	84aa                	mv	s1,a0
    if(mem == 0){
    80001602:	c51d                	beqz	a0,80001630 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001604:	6605                	lui	a2,0x1
    80001606:	4581                	li	a1,0
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	84e080e7          	jalr	-1970(ra) # 80000e56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001610:	4779                	li	a4,30
    80001612:	86a6                	mv	a3,s1
    80001614:	6605                	lui	a2,0x1
    80001616:	85ca                	mv	a1,s2
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c6e080e7          	jalr	-914(ra) # 80001288 <mappages>
    80001622:	e905                	bnez	a0,80001652 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001624:	6785                	lui	a5,0x1
    80001626:	993e                	add	s2,s2,a5
    80001628:	fd4968e3          	bltu	s2,s4,800015f8 <uvmalloc+0x2c>
  return newsz;
    8000162c:	8552                	mv	a0,s4
    8000162e:	a809                	j	80001640 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001630:	864e                	mv	a2,s3
    80001632:	85ca                	mv	a1,s2
    80001634:	8556                	mv	a0,s5
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	f4e080e7          	jalr	-178(ra) # 80001584 <uvmdealloc>
      return 0;
    8000163e:	4501                	li	a0,0
}
    80001640:	70e2                	ld	ra,56(sp)
    80001642:	7442                	ld	s0,48(sp)
    80001644:	74a2                	ld	s1,40(sp)
    80001646:	7902                	ld	s2,32(sp)
    80001648:	69e2                	ld	s3,24(sp)
    8000164a:	6a42                	ld	s4,16(sp)
    8000164c:	6aa2                	ld	s5,8(sp)
    8000164e:	6121                	addi	sp,sp,64
    80001650:	8082                	ret
      kfree(mem);
    80001652:	8526                	mv	a0,s1
    80001654:	fffff097          	auipc	ra,0xfffff
    80001658:	44c080e7          	jalr	1100(ra) # 80000aa0 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000165c:	864e                	mv	a2,s3
    8000165e:	85ca                	mv	a1,s2
    80001660:	8556                	mv	a0,s5
    80001662:	00000097          	auipc	ra,0x0
    80001666:	f22080e7          	jalr	-222(ra) # 80001584 <uvmdealloc>
      return 0;
    8000166a:	4501                	li	a0,0
    8000166c:	bfd1                	j	80001640 <uvmalloc+0x74>
    return oldsz;
    8000166e:	852e                	mv	a0,a1
}
    80001670:	8082                	ret
  return newsz;
    80001672:	8532                	mv	a0,a2
    80001674:	b7f1                	j	80001640 <uvmalloc+0x74>

0000000080001676 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001676:	7179                	addi	sp,sp,-48
    80001678:	f406                	sd	ra,40(sp)
    8000167a:	f022                	sd	s0,32(sp)
    8000167c:	ec26                	sd	s1,24(sp)
    8000167e:	e84a                	sd	s2,16(sp)
    80001680:	e44e                	sd	s3,8(sp)
    80001682:	e052                	sd	s4,0(sp)
    80001684:	1800                	addi	s0,sp,48
    80001686:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001688:	84aa                	mv	s1,a0
    8000168a:	6905                	lui	s2,0x1
    8000168c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000168e:	4985                	li	s3,1
    80001690:	a821                	j	800016a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001692:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001694:	0532                	slli	a0,a0,0xc
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	fe0080e7          	jalr	-32(ra) # 80001676 <freewalk>
      pagetable[i] = 0;
    8000169e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016a2:	04a1                	addi	s1,s1,8
    800016a4:	03248163          	beq	s1,s2,800016c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016aa:	00f57793          	andi	a5,a0,15
    800016ae:	ff3782e3          	beq	a5,s3,80001692 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016b2:	8905                	andi	a0,a0,1
    800016b4:	d57d                	beqz	a0,800016a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016b6:	00007517          	auipc	a0,0x7
    800016ba:	ada50513          	addi	a0,a0,-1318 # 80008190 <digits+0x150>
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	e8a080e7          	jalr	-374(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800016c6:	8552                	mv	a0,s4
    800016c8:	fffff097          	auipc	ra,0xfffff
    800016cc:	3d8080e7          	jalr	984(ra) # 80000aa0 <kfree>
}
    800016d0:	70a2                	ld	ra,40(sp)
    800016d2:	7402                	ld	s0,32(sp)
    800016d4:	64e2                	ld	s1,24(sp)
    800016d6:	6942                	ld	s2,16(sp)
    800016d8:	69a2                	ld	s3,8(sp)
    800016da:	6a02                	ld	s4,0(sp)
    800016dc:	6145                	addi	sp,sp,48
    800016de:	8082                	ret

00000000800016e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016e0:	1101                	addi	sp,sp,-32
    800016e2:	ec06                	sd	ra,24(sp)
    800016e4:	e822                	sd	s0,16(sp)
    800016e6:	e426                	sd	s1,8(sp)
    800016e8:	1000                	addi	s0,sp,32
    800016ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800016ec:	e999                	bnez	a1,80001702 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016ee:	8526                	mv	a0,s1
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	f86080e7          	jalr	-122(ra) # 80001676 <freewalk>
}
    800016f8:	60e2                	ld	ra,24(sp)
    800016fa:	6442                	ld	s0,16(sp)
    800016fc:	64a2                	ld	s1,8(sp)
    800016fe:	6105                	addi	sp,sp,32
    80001700:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001702:	6605                	lui	a2,0x1
    80001704:	167d                	addi	a2,a2,-1
    80001706:	962e                	add	a2,a2,a1
    80001708:	4685                	li	a3,1
    8000170a:	8231                	srli	a2,a2,0xc
    8000170c:	4581                	li	a1,0
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	d12080e7          	jalr	-750(ra) # 80001420 <uvmunmap>
    80001716:	bfe1                	j	800016ee <uvmfree+0xe>

0000000080001718 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001718:	7139                	addi	sp,sp,-64
    8000171a:	fc06                	sd	ra,56(sp)
    8000171c:	f822                	sd	s0,48(sp)
    8000171e:	f426                	sd	s1,40(sp)
    80001720:	f04a                	sd	s2,32(sp)
    80001722:	ec4e                	sd	s3,24(sp)
    80001724:	e852                	sd	s4,16(sp)
    80001726:	e456                	sd	s5,8(sp)
    80001728:	e05a                	sd	s6,0(sp)
    8000172a:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000172c:	c25d                	beqz	a2,800017d2 <uvmcopy+0xba>
    8000172e:	8aaa                	mv	s5,a0
    80001730:	8a2e                	mv	s4,a1
    80001732:	89b2                	mv	s3,a2
    80001734:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    80001736:	4601                	li	a2,0
    80001738:	85a6                	mv	a1,s1
    8000173a:	8556                	mv	a0,s5
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	a06080e7          	jalr	-1530(ra) # 80001142 <walk>
    80001744:	c131                	beqz	a0,80001788 <uvmcopy+0x70>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001746:	6118                	ld	a4,0(a0)
    80001748:	00177793          	andi	a5,a4,1
    8000174c:	c7b1                	beqz	a5,80001798 <uvmcopy+0x80>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000174e:	00a75913          	srli	s2,a4,0xa
    80001752:	0932                	slli	s2,s2,0xc
    //for cow lab
    
    *pte &=~PTE_W;
    80001754:	9b6d                	andi	a4,a4,-5
    *pte |=PTE_RSW;
    80001756:	10076713          	ori	a4,a4,256
    8000175a:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte);
    //if((mem = kalloc()) == 0)
     // goto err;
    //memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new,i,PGSIZE,pa,flags)!=0){
    8000175c:	3fb77713          	andi	a4,a4,1019
    80001760:	86ca                	mv	a3,s2
    80001762:	6605                	lui	a2,0x1
    80001764:	85a6                	mv	a1,s1
    80001766:	8552                	mv	a0,s4
    80001768:	00000097          	auipc	ra,0x0
    8000176c:	b20080e7          	jalr	-1248(ra) # 80001288 <mappages>
    80001770:	8b2a                	mv	s6,a0
    80001772:	e91d                	bnez	a0,800017a8 <uvmcopy+0x90>
      goto err;
    }
    incref(pa);
    80001774:	854a                	mv	a0,s2
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	2ae080e7          	jalr	686(ra) # 80000a24 <incref>
  for(i = 0; i < sz; i += PGSIZE){
    8000177e:	6785                	lui	a5,0x1
    80001780:	94be                	add	s1,s1,a5
    80001782:	fb34eae3          	bltu	s1,s3,80001736 <uvmcopy+0x1e>
    80001786:	a81d                	j	800017bc <uvmcopy+0xa4>
      panic("uvmcopy: pte should exist");
    80001788:	00007517          	auipc	a0,0x7
    8000178c:	a1850513          	addi	a0,a0,-1512 # 800081a0 <digits+0x160>
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	db8080e7          	jalr	-584(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001798:	00007517          	auipc	a0,0x7
    8000179c:	a2850513          	addi	a0,a0,-1496 # 800081c0 <digits+0x180>
    800017a0:	fffff097          	auipc	ra,0xfffff
    800017a4:	da8080e7          	jalr	-600(ra) # 80000548 <panic>
        // goto err;
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017a8:	4685                	li	a3,1
    800017aa:	00c4d613          	srli	a2,s1,0xc
    800017ae:	4581                	li	a1,0
    800017b0:	8552                	mv	a0,s4
    800017b2:	00000097          	auipc	ra,0x0
    800017b6:	c6e080e7          	jalr	-914(ra) # 80001420 <uvmunmap>
  return -1;
    800017ba:	5b7d                	li	s6,-1
}
    800017bc:	855a                	mv	a0,s6
    800017be:	70e2                	ld	ra,56(sp)
    800017c0:	7442                	ld	s0,48(sp)
    800017c2:	74a2                	ld	s1,40(sp)
    800017c4:	7902                	ld	s2,32(sp)
    800017c6:	69e2                	ld	s3,24(sp)
    800017c8:	6a42                	ld	s4,16(sp)
    800017ca:	6aa2                	ld	s5,8(sp)
    800017cc:	6b02                	ld	s6,0(sp)
    800017ce:	6121                	addi	sp,sp,64
    800017d0:	8082                	ret
  return 0;
    800017d2:	4b01                	li	s6,0
    800017d4:	b7e5                	j	800017bc <uvmcopy+0xa4>

00000000800017d6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017d6:	1141                	addi	sp,sp,-16
    800017d8:	e406                	sd	ra,8(sp)
    800017da:	e022                	sd	s0,0(sp)
    800017dc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017de:	4601                	li	a2,0
    800017e0:	00000097          	auipc	ra,0x0
    800017e4:	962080e7          	jalr	-1694(ra) # 80001142 <walk>
  if(pte == 0)
    800017e8:	c901                	beqz	a0,800017f8 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017ea:	611c                	ld	a5,0(a0)
    800017ec:	9bbd                	andi	a5,a5,-17
    800017ee:	e11c                	sd	a5,0(a0)
}
    800017f0:	60a2                	ld	ra,8(sp)
    800017f2:	6402                	ld	s0,0(sp)
    800017f4:	0141                	addi	sp,sp,16
    800017f6:	8082                	ret
    panic("uvmclear");
    800017f8:	00007517          	auipc	a0,0x7
    800017fc:	9e850513          	addi	a0,a0,-1560 # 800081e0 <digits+0x1a0>
    80001800:	fffff097          	auipc	ra,0xfffff
    80001804:	d48080e7          	jalr	-696(ra) # 80000548 <panic>

0000000080001808 <copyout>:
{
  uint64 n, va0, pa0;
  pte_t* mypte;
  char*mem;

  while(len > 0){
    80001808:	cae1                	beqz	a3,800018d8 <copyout+0xd0>
{
    8000180a:	711d                	addi	sp,sp,-96
    8000180c:	ec86                	sd	ra,88(sp)
    8000180e:	e8a2                	sd	s0,80(sp)
    80001810:	e4a6                	sd	s1,72(sp)
    80001812:	e0ca                	sd	s2,64(sp)
    80001814:	fc4e                	sd	s3,56(sp)
    80001816:	f852                	sd	s4,48(sp)
    80001818:	f456                	sd	s5,40(sp)
    8000181a:	f05a                	sd	s6,32(sp)
    8000181c:	ec5e                	sd	s7,24(sp)
    8000181e:	e862                	sd	s8,16(sp)
    80001820:	e466                	sd	s9,8(sp)
    80001822:	1080                	addi	s0,sp,96
    80001824:	8baa                	mv	s7,a0
    80001826:	84ae                	mv	s1,a1
    80001828:	8b32                	mv	s6,a2
    8000182a:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    8000182c:	7c7d                	lui	s8,0xfffff
    8000182e:	a815                	j	80001862 <copyout+0x5a>
    if(pa0 == 0)
      return -1;
    mypte=walk(pagetable,va0,0);
    if(((*mypte)&PTE_W)==0){
        if(((*mypte)&PTE_RSW)==0){
          panic("write unwritable page error");
    80001830:	00007517          	auipc	a0,0x7
    80001834:	9c050513          	addi	a0,a0,-1600 # 800081f0 <digits+0x1b0>
    80001838:	fffff097          	auipc	ra,0xfffff
    8000183c:	d10080e7          	jalr	-752(ra) # 80000548 <panic>
        }
    }
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001840:	41448533          	sub	a0,s1,s4
    80001844:	0009061b          	sext.w	a2,s2
    80001848:	85da                	mv	a1,s6
    8000184a:	954e                	add	a0,a0,s3
    8000184c:	fffff097          	auipc	ra,0xfffff
    80001850:	66a080e7          	jalr	1642(ra) # 80000eb6 <memmove>

    len -= n;
    80001854:	412a8ab3          	sub	s5,s5,s2
    src += n;
    80001858:	9b4a                	add	s6,s6,s2
    dstva = va0 + PGSIZE;
    8000185a:	6485                	lui	s1,0x1
    8000185c:	94d2                	add	s1,s1,s4
  while(len > 0){
    8000185e:	060a8b63          	beqz	s5,800018d4 <copyout+0xcc>
    va0 = PGROUNDDOWN(dstva);
    80001862:	0184fa33          	and	s4,s1,s8
    pa0 = walkaddr(pagetable, va0);
    80001866:	85d2                	mv	a1,s4
    80001868:	855e                	mv	a0,s7
    8000186a:	00000097          	auipc	ra,0x0
    8000186e:	97e080e7          	jalr	-1666(ra) # 800011e8 <walkaddr>
    80001872:	89aa                	mv	s3,a0
    if(pa0 == 0)
    80001874:	c525                	beqz	a0,800018dc <copyout+0xd4>
    mypte=walk(pagetable,va0,0);
    80001876:	4601                	li	a2,0
    80001878:	85d2                	mv	a1,s4
    8000187a:	855e                	mv	a0,s7
    8000187c:	00000097          	auipc	ra,0x0
    80001880:	8c6080e7          	jalr	-1850(ra) # 80001142 <walk>
    80001884:	8caa                	mv	s9,a0
    if(((*mypte)&PTE_W)==0){
    80001886:	611c                	ld	a5,0(a0)
    80001888:	0047f713          	andi	a4,a5,4
    8000188c:	ef05                	bnez	a4,800018c4 <copyout+0xbc>
        if(((*mypte)&PTE_RSW)==0){
    8000188e:	1007f793          	andi	a5,a5,256
    80001892:	dfd9                	beqz	a5,80001830 <copyout+0x28>
          mem=kalloc();
    80001894:	fffff097          	auipc	ra,0xfffff
    80001898:	394080e7          	jalr	916(ra) # 80000c28 <kalloc>
    8000189c:	892a                	mv	s2,a0
          memmove((void*)mem, (void*)pa0, PGSIZE);
    8000189e:	6605                	lui	a2,0x1
    800018a0:	85ce                	mv	a1,s3
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	614080e7          	jalr	1556(ra) # 80000eb6 <memmove>
          kfree((void*)pa0);
    800018aa:	854e                	mv	a0,s3
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	1f4080e7          	jalr	500(ra) # 80000aa0 <kfree>
          *mypte=(PA2PTE(mem))|PTE_W|PTE_R|PTE_V|PTE_U|PTE_X;
    800018b4:	89ca                	mv	s3,s2
    800018b6:	00c95913          	srli	s2,s2,0xc
    800018ba:	092a                	slli	s2,s2,0xa
    800018bc:	01f96913          	ori	s2,s2,31
    800018c0:	012cb023          	sd	s2,0(s9)
    n = PGSIZE - (dstva - va0);
    800018c4:	409a0933          	sub	s2,s4,s1
    800018c8:	6785                	lui	a5,0x1
    800018ca:	993e                	add	s2,s2,a5
    if(n > len)
    800018cc:	f72afae3          	bgeu	s5,s2,80001840 <copyout+0x38>
    800018d0:	8956                	mv	s2,s5
    800018d2:	b7bd                	j	80001840 <copyout+0x38>
  }
  return 0;
    800018d4:	4501                	li	a0,0
    800018d6:	a021                	j	800018de <copyout+0xd6>
    800018d8:	4501                	li	a0,0
}
    800018da:	8082                	ret
      return -1;
    800018dc:	557d                	li	a0,-1
}
    800018de:	60e6                	ld	ra,88(sp)
    800018e0:	6446                	ld	s0,80(sp)
    800018e2:	64a6                	ld	s1,72(sp)
    800018e4:	6906                	ld	s2,64(sp)
    800018e6:	79e2                	ld	s3,56(sp)
    800018e8:	7a42                	ld	s4,48(sp)
    800018ea:	7aa2                	ld	s5,40(sp)
    800018ec:	7b02                	ld	s6,32(sp)
    800018ee:	6be2                	ld	s7,24(sp)
    800018f0:	6c42                	ld	s8,16(sp)
    800018f2:	6ca2                	ld	s9,8(sp)
    800018f4:	6125                	addi	sp,sp,96
    800018f6:	8082                	ret

00000000800018f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018f8:	c6bd                	beqz	a3,80001966 <copyin+0x6e>
{
    800018fa:	715d                	addi	sp,sp,-80
    800018fc:	e486                	sd	ra,72(sp)
    800018fe:	e0a2                	sd	s0,64(sp)
    80001900:	fc26                	sd	s1,56(sp)
    80001902:	f84a                	sd	s2,48(sp)
    80001904:	f44e                	sd	s3,40(sp)
    80001906:	f052                	sd	s4,32(sp)
    80001908:	ec56                	sd	s5,24(sp)
    8000190a:	e85a                	sd	s6,16(sp)
    8000190c:	e45e                	sd	s7,8(sp)
    8000190e:	e062                	sd	s8,0(sp)
    80001910:	0880                	addi	s0,sp,80
    80001912:	8b2a                	mv	s6,a0
    80001914:	8a2e                	mv	s4,a1
    80001916:	8c32                	mv	s8,a2
    80001918:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000191a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000191c:	6a85                	lui	s5,0x1
    8000191e:	a015                	j	80001942 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001920:	9562                	add	a0,a0,s8
    80001922:	0004861b          	sext.w	a2,s1
    80001926:	412505b3          	sub	a1,a0,s2
    8000192a:	8552                	mv	a0,s4
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	58a080e7          	jalr	1418(ra) # 80000eb6 <memmove>

    len -= n;
    80001934:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001938:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000193a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000193e:	02098263          	beqz	s3,80001962 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001942:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001946:	85ca                	mv	a1,s2
    80001948:	855a                	mv	a0,s6
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	89e080e7          	jalr	-1890(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    80001952:	cd01                	beqz	a0,8000196a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001954:	418904b3          	sub	s1,s2,s8
    80001958:	94d6                	add	s1,s1,s5
    if(n > len)
    8000195a:	fc99f3e3          	bgeu	s3,s1,80001920 <copyin+0x28>
    8000195e:	84ce                	mv	s1,s3
    80001960:	b7c1                	j	80001920 <copyin+0x28>
  }
  return 0;
    80001962:	4501                	li	a0,0
    80001964:	a021                	j	8000196c <copyin+0x74>
    80001966:	4501                	li	a0,0
}
    80001968:	8082                	ret
      return -1;
    8000196a:	557d                	li	a0,-1
}
    8000196c:	60a6                	ld	ra,72(sp)
    8000196e:	6406                	ld	s0,64(sp)
    80001970:	74e2                	ld	s1,56(sp)
    80001972:	7942                	ld	s2,48(sp)
    80001974:	79a2                	ld	s3,40(sp)
    80001976:	7a02                	ld	s4,32(sp)
    80001978:	6ae2                	ld	s5,24(sp)
    8000197a:	6b42                	ld	s6,16(sp)
    8000197c:	6ba2                	ld	s7,8(sp)
    8000197e:	6c02                	ld	s8,0(sp)
    80001980:	6161                	addi	sp,sp,80
    80001982:	8082                	ret

0000000080001984 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001984:	c6c5                	beqz	a3,80001a2c <copyinstr+0xa8>
{
    80001986:	715d                	addi	sp,sp,-80
    80001988:	e486                	sd	ra,72(sp)
    8000198a:	e0a2                	sd	s0,64(sp)
    8000198c:	fc26                	sd	s1,56(sp)
    8000198e:	f84a                	sd	s2,48(sp)
    80001990:	f44e                	sd	s3,40(sp)
    80001992:	f052                	sd	s4,32(sp)
    80001994:	ec56                	sd	s5,24(sp)
    80001996:	e85a                	sd	s6,16(sp)
    80001998:	e45e                	sd	s7,8(sp)
    8000199a:	0880                	addi	s0,sp,80
    8000199c:	8a2a                	mv	s4,a0
    8000199e:	8b2e                	mv	s6,a1
    800019a0:	8bb2                	mv	s7,a2
    800019a2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019a4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019a6:	6985                	lui	s3,0x1
    800019a8:	a035                	j	800019d4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019aa:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019ae:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019b0:	0017b793          	seqz	a5,a5
    800019b4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019b8:	60a6                	ld	ra,72(sp)
    800019ba:	6406                	ld	s0,64(sp)
    800019bc:	74e2                	ld	s1,56(sp)
    800019be:	7942                	ld	s2,48(sp)
    800019c0:	79a2                	ld	s3,40(sp)
    800019c2:	7a02                	ld	s4,32(sp)
    800019c4:	6ae2                	ld	s5,24(sp)
    800019c6:	6b42                	ld	s6,16(sp)
    800019c8:	6ba2                	ld	s7,8(sp)
    800019ca:	6161                	addi	sp,sp,80
    800019cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800019ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019d2:	c8a9                	beqz	s1,80001a24 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019d8:	85ca                	mv	a1,s2
    800019da:	8552                	mv	a0,s4
    800019dc:	00000097          	auipc	ra,0x0
    800019e0:	80c080e7          	jalr	-2036(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    800019e4:	c131                	beqz	a0,80001a28 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019e6:	41790833          	sub	a6,s2,s7
    800019ea:	984e                	add	a6,a6,s3
    if(n > max)
    800019ec:	0104f363          	bgeu	s1,a6,800019f2 <copyinstr+0x6e>
    800019f0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019f2:	955e                	add	a0,a0,s7
    800019f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019f8:	fc080be3          	beqz	a6,800019ce <copyinstr+0x4a>
    800019fc:	985a                	add	a6,a6,s6
    800019fe:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a00:	41650633          	sub	a2,a0,s6
    80001a04:	14fd                	addi	s1,s1,-1
    80001a06:	9b26                	add	s6,s6,s1
    80001a08:	00f60733          	add	a4,a2,a5
    80001a0c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9000>
    80001a10:	df49                	beqz	a4,800019aa <copyinstr+0x26>
        *dst = *p;
    80001a12:	00e78023          	sb	a4,0(a5)
      --max;
    80001a16:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a1a:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a1c:	ff0796e3          	bne	a5,a6,80001a08 <copyinstr+0x84>
      dst++;
    80001a20:	8b42                	mv	s6,a6
    80001a22:	b775                	j	800019ce <copyinstr+0x4a>
    80001a24:	4781                	li	a5,0
    80001a26:	b769                	j	800019b0 <copyinstr+0x2c>
      return -1;
    80001a28:	557d                	li	a0,-1
    80001a2a:	b779                	j	800019b8 <copyinstr+0x34>
  int got_null = 0;
    80001a2c:	4781                	li	a5,0
  if(got_null){
    80001a2e:	0017b793          	seqz	a5,a5
    80001a32:	40f00533          	neg	a0,a5
}
    80001a36:	8082                	ret

0000000080001a38 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a38:	1101                	addi	sp,sp,-32
    80001a3a:	ec06                	sd	ra,24(sp)
    80001a3c:	e822                	sd	s0,16(sp)
    80001a3e:	e426                	sd	s1,8(sp)
    80001a40:	1000                	addi	s0,sp,32
    80001a42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	29c080e7          	jalr	668(ra) # 80000ce0 <holding>
    80001a4c:	c909                	beqz	a0,80001a5e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a4e:	749c                	ld	a5,40(s1)
    80001a50:	00978f63          	beq	a5,s1,80001a6e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a54:	60e2                	ld	ra,24(sp)
    80001a56:	6442                	ld	s0,16(sp)
    80001a58:	64a2                	ld	s1,8(sp)
    80001a5a:	6105                	addi	sp,sp,32
    80001a5c:	8082                	ret
    panic("wakeup1");
    80001a5e:	00006517          	auipc	a0,0x6
    80001a62:	7b250513          	addi	a0,a0,1970 # 80008210 <digits+0x1d0>
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	ae2080e7          	jalr	-1310(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a6e:	4c98                	lw	a4,24(s1)
    80001a70:	4785                	li	a5,1
    80001a72:	fef711e3          	bne	a4,a5,80001a54 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a76:	4789                	li	a5,2
    80001a78:	cc9c                	sw	a5,24(s1)
}
    80001a7a:	bfe9                	j	80001a54 <wakeup1+0x1c>

0000000080001a7c <procinit>:
{
    80001a7c:	715d                	addi	sp,sp,-80
    80001a7e:	e486                	sd	ra,72(sp)
    80001a80:	e0a2                	sd	s0,64(sp)
    80001a82:	fc26                	sd	s1,56(sp)
    80001a84:	f84a                	sd	s2,48(sp)
    80001a86:	f44e                	sd	s3,40(sp)
    80001a88:	f052                	sd	s4,32(sp)
    80001a8a:	ec56                	sd	s5,24(sp)
    80001a8c:	e85a                	sd	s6,16(sp)
    80001a8e:	e45e                	sd	s7,8(sp)
    80001a90:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a92:	00006597          	auipc	a1,0x6
    80001a96:	78658593          	addi	a1,a1,1926 # 80008218 <digits+0x1d8>
    80001a9a:	00230517          	auipc	a0,0x230
    80001a9e:	eb650513          	addi	a0,a0,-330 # 80231950 <pid_lock>
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	228080e7          	jalr	552(ra) # 80000cca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aaa:	00230917          	auipc	s2,0x230
    80001aae:	2be90913          	addi	s2,s2,702 # 80231d68 <proc>
      initlock(&p->lock, "proc");
    80001ab2:	00006b97          	auipc	s7,0x6
    80001ab6:	76eb8b93          	addi	s7,s7,1902 # 80008220 <digits+0x1e0>
      uint64 va = KSTACK((int) (p - proc));
    80001aba:	8b4a                	mv	s6,s2
    80001abc:	00006a97          	auipc	s5,0x6
    80001ac0:	544a8a93          	addi	s5,s5,1348 # 80008000 <etext>
    80001ac4:	040009b7          	lui	s3,0x4000
    80001ac8:	19fd                	addi	s3,s3,-1
    80001aca:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001acc:	00236a17          	auipc	s4,0x236
    80001ad0:	c9ca0a13          	addi	s4,s4,-868 # 80237768 <tickslock>
      initlock(&p->lock, "proc");
    80001ad4:	85de                	mv	a1,s7
    80001ad6:	854a                	mv	a0,s2
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	1f2080e7          	jalr	498(ra) # 80000cca <initlock>
      char *pa = kalloc();
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	148080e7          	jalr	328(ra) # 80000c28 <kalloc>
    80001ae8:	85aa                	mv	a1,a0
      if(pa == 0)
    80001aea:	c929                	beqz	a0,80001b3c <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001aec:	416904b3          	sub	s1,s2,s6
    80001af0:	848d                	srai	s1,s1,0x3
    80001af2:	000ab783          	ld	a5,0(s5)
    80001af6:	02f484b3          	mul	s1,s1,a5
    80001afa:	2485                	addiw	s1,s1,1
    80001afc:	00d4949b          	slliw	s1,s1,0xd
    80001b00:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b04:	4699                	li	a3,6
    80001b06:	6605                	lui	a2,0x1
    80001b08:	8526                	mv	a0,s1
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	80c080e7          	jalr	-2036(ra) # 80001316 <kvmmap>
      p->kstack = va;
    80001b12:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b16:	16890913          	addi	s2,s2,360
    80001b1a:	fb491de3          	bne	s2,s4,80001ad4 <procinit+0x58>
  kvminithart();
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	600080e7          	jalr	1536(ra) # 8000111e <kvminithart>
}
    80001b26:	60a6                	ld	ra,72(sp)
    80001b28:	6406                	ld	s0,64(sp)
    80001b2a:	74e2                	ld	s1,56(sp)
    80001b2c:	7942                	ld	s2,48(sp)
    80001b2e:	79a2                	ld	s3,40(sp)
    80001b30:	7a02                	ld	s4,32(sp)
    80001b32:	6ae2                	ld	s5,24(sp)
    80001b34:	6b42                	ld	s6,16(sp)
    80001b36:	6ba2                	ld	s7,8(sp)
    80001b38:	6161                	addi	sp,sp,80
    80001b3a:	8082                	ret
        panic("kalloc");
    80001b3c:	00006517          	auipc	a0,0x6
    80001b40:	6ec50513          	addi	a0,a0,1772 # 80008228 <digits+0x1e8>
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	a04080e7          	jalr	-1532(ra) # 80000548 <panic>

0000000080001b4c <cpuid>:
{
    80001b4c:	1141                	addi	sp,sp,-16
    80001b4e:	e422                	sd	s0,8(sp)
    80001b50:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b52:	8512                	mv	a0,tp
}
    80001b54:	2501                	sext.w	a0,a0
    80001b56:	6422                	ld	s0,8(sp)
    80001b58:	0141                	addi	sp,sp,16
    80001b5a:	8082                	ret

0000000080001b5c <mycpu>:
mycpu(void) {
    80001b5c:	1141                	addi	sp,sp,-16
    80001b5e:	e422                	sd	s0,8(sp)
    80001b60:	0800                	addi	s0,sp,16
    80001b62:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b64:	2781                	sext.w	a5,a5
    80001b66:	079e                	slli	a5,a5,0x7
}
    80001b68:	00230517          	auipc	a0,0x230
    80001b6c:	e0050513          	addi	a0,a0,-512 # 80231968 <cpus>
    80001b70:	953e                	add	a0,a0,a5
    80001b72:	6422                	ld	s0,8(sp)
    80001b74:	0141                	addi	sp,sp,16
    80001b76:	8082                	ret

0000000080001b78 <myproc>:
myproc(void) {
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
  push_off();
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	18c080e7          	jalr	396(ra) # 80000d0e <push_off>
    80001b8a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b8c:	2781                	sext.w	a5,a5
    80001b8e:	079e                	slli	a5,a5,0x7
    80001b90:	00230717          	auipc	a4,0x230
    80001b94:	dc070713          	addi	a4,a4,-576 # 80231950 <pid_lock>
    80001b98:	97ba                	add	a5,a5,a4
    80001b9a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	212080e7          	jalr	530(ra) # 80000dae <pop_off>
}
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <forkret>:
{
    80001bb0:	1141                	addi	sp,sp,-16
    80001bb2:	e406                	sd	ra,8(sp)
    80001bb4:	e022                	sd	s0,0(sp)
    80001bb6:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	fc0080e7          	jalr	-64(ra) # 80001b78 <myproc>
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	24e080e7          	jalr	590(ra) # 80000e0e <release>
  if (first) {
    80001bc8:	00007797          	auipc	a5,0x7
    80001bcc:	ca87a783          	lw	a5,-856(a5) # 80008870 <first.1672>
    80001bd0:	eb89                	bnez	a5,80001be2 <forkret+0x32>
  usertrapret();
    80001bd2:	00001097          	auipc	ra,0x1
    80001bd6:	cb8080e7          	jalr	-840(ra) # 8000288a <usertrapret>
}
    80001bda:	60a2                	ld	ra,8(sp)
    80001bdc:	6402                	ld	s0,0(sp)
    80001bde:	0141                	addi	sp,sp,16
    80001be0:	8082                	ret
    first = 0;
    80001be2:	00007797          	auipc	a5,0x7
    80001be6:	c807a723          	sw	zero,-882(a5) # 80008870 <first.1672>
    fsinit(ROOTDEV);
    80001bea:	4505                	li	a0,1
    80001bec:	00002097          	auipc	ra,0x2
    80001bf0:	a04080e7          	jalr	-1532(ra) # 800035f0 <fsinit>
    80001bf4:	bff9                	j	80001bd2 <forkret+0x22>

0000000080001bf6 <allocpid>:
allocpid() {
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	e04a                	sd	s2,0(sp)
    80001c00:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c02:	00230917          	auipc	s2,0x230
    80001c06:	d4e90913          	addi	s2,s2,-690 # 80231950 <pid_lock>
    80001c0a:	854a                	mv	a0,s2
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	14e080e7          	jalr	334(ra) # 80000d5a <acquire>
  pid = nextpid;
    80001c14:	00007797          	auipc	a5,0x7
    80001c18:	c6078793          	addi	a5,a5,-928 # 80008874 <nextpid>
    80001c1c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c1e:	0014871b          	addiw	a4,s1,1
    80001c22:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c24:	854a                	mv	a0,s2
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	1e8080e7          	jalr	488(ra) # 80000e0e <release>
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret

0000000080001c3c <proc_pagetable>:
{
    80001c3c:	1101                	addi	sp,sp,-32
    80001c3e:	ec06                	sd	ra,24(sp)
    80001c40:	e822                	sd	s0,16(sp)
    80001c42:	e426                	sd	s1,8(sp)
    80001c44:	e04a                	sd	s2,0(sp)
    80001c46:	1000                	addi	s0,sp,32
    80001c48:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	89a080e7          	jalr	-1894(ra) # 800014e4 <uvmcreate>
    80001c52:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c54:	c121                	beqz	a0,80001c94 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c56:	4729                	li	a4,10
    80001c58:	00005697          	auipc	a3,0x5
    80001c5c:	3a868693          	addi	a3,a3,936 # 80007000 <_trampoline>
    80001c60:	6605                	lui	a2,0x1
    80001c62:	040005b7          	lui	a1,0x4000
    80001c66:	15fd                	addi	a1,a1,-1
    80001c68:	05b2                	slli	a1,a1,0xc
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	61e080e7          	jalr	1566(ra) # 80001288 <mappages>
    80001c72:	02054863          	bltz	a0,80001ca2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c76:	4719                	li	a4,6
    80001c78:	05893683          	ld	a3,88(s2)
    80001c7c:	6605                	lui	a2,0x1
    80001c7e:	020005b7          	lui	a1,0x2000
    80001c82:	15fd                	addi	a1,a1,-1
    80001c84:	05b6                	slli	a1,a1,0xd
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	600080e7          	jalr	1536(ra) # 80001288 <mappages>
    80001c90:	02054163          	bltz	a0,80001cb2 <proc_pagetable+0x76>
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ca2:	4581                	li	a1,0
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	a3a080e7          	jalr	-1478(ra) # 800016e0 <uvmfree>
    return 0;
    80001cae:	4481                	li	s1,0
    80001cb0:	b7d5                	j	80001c94 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cb2:	4681                	li	a3,0
    80001cb4:	4605                	li	a2,1
    80001cb6:	040005b7          	lui	a1,0x4000
    80001cba:	15fd                	addi	a1,a1,-1
    80001cbc:	05b2                	slli	a1,a1,0xc
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	760080e7          	jalr	1888(ra) # 80001420 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cc8:	4581                	li	a1,0
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	a14080e7          	jalr	-1516(ra) # 800016e0 <uvmfree>
    return 0;
    80001cd4:	4481                	li	s1,0
    80001cd6:	bf7d                	j	80001c94 <proc_pagetable+0x58>

0000000080001cd8 <proc_freepagetable>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	e04a                	sd	s2,0(sp)
    80001ce2:	1000                	addi	s0,sp,32
    80001ce4:	84aa                	mv	s1,a0
    80001ce6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce8:	4681                	li	a3,0
    80001cea:	4605                	li	a2,1
    80001cec:	040005b7          	lui	a1,0x4000
    80001cf0:	15fd                	addi	a1,a1,-1
    80001cf2:	05b2                	slli	a1,a1,0xc
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	72c080e7          	jalr	1836(ra) # 80001420 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cfc:	4681                	li	a3,0
    80001cfe:	4605                	li	a2,1
    80001d00:	020005b7          	lui	a1,0x2000
    80001d04:	15fd                	addi	a1,a1,-1
    80001d06:	05b6                	slli	a1,a1,0xd
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	716080e7          	jalr	1814(ra) # 80001420 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d12:	85ca                	mv	a1,s2
    80001d14:	8526                	mv	a0,s1
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	9ca080e7          	jalr	-1590(ra) # 800016e0 <uvmfree>
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6902                	ld	s2,0(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <freeproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
    80001d34:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d36:	6d28                	ld	a0,88(a0)
    80001d38:	c509                	beqz	a0,80001d42 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	d66080e7          	jalr	-666(ra) # 80000aa0 <kfree>
  p->trapframe = 0;
    80001d42:	0404bc23          	sd	zero,88(s1) # 1058 <_entry-0x7fffefa8>
  if(p->pagetable)
    80001d46:	68a8                	ld	a0,80(s1)
    80001d48:	c511                	beqz	a0,80001d54 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d4a:	64ac                	ld	a1,72(s1)
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	f8c080e7          	jalr	-116(ra) # 80001cd8 <proc_freepagetable>
  p->pagetable = 0;
    80001d54:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d58:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d5c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d60:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d64:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d68:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d6c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d70:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d74:	0004ac23          	sw	zero,24(s1)
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret

0000000080001d82 <allocproc>:
{
    80001d82:	1101                	addi	sp,sp,-32
    80001d84:	ec06                	sd	ra,24(sp)
    80001d86:	e822                	sd	s0,16(sp)
    80001d88:	e426                	sd	s1,8(sp)
    80001d8a:	e04a                	sd	s2,0(sp)
    80001d8c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8e:	00230497          	auipc	s1,0x230
    80001d92:	fda48493          	addi	s1,s1,-38 # 80231d68 <proc>
    80001d96:	00236917          	auipc	s2,0x236
    80001d9a:	9d290913          	addi	s2,s2,-1582 # 80237768 <tickslock>
    acquire(&p->lock);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	fba080e7          	jalr	-70(ra) # 80000d5a <acquire>
    if(p->state == UNUSED) {
    80001da8:	4c9c                	lw	a5,24(s1)
    80001daa:	cf81                	beqz	a5,80001dc2 <allocproc+0x40>
      release(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	060080e7          	jalr	96(ra) # 80000e0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db6:	16848493          	addi	s1,s1,360
    80001dba:	ff2492e3          	bne	s1,s2,80001d9e <allocproc+0x1c>
  return 0;
    80001dbe:	4481                	li	s1,0
    80001dc0:	a0b9                	j	80001e0e <allocproc+0x8c>
  p->pid = allocpid();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	e34080e7          	jalr	-460(ra) # 80001bf6 <allocpid>
    80001dca:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	e5c080e7          	jalr	-420(ra) # 80000c28 <kalloc>
    80001dd4:	892a                	mv	s2,a0
    80001dd6:	eca8                	sd	a0,88(s1)
    80001dd8:	c131                	beqz	a0,80001e1c <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e60080e7          	jalr	-416(ra) # 80001c3c <proc_pagetable>
    80001de4:	892a                	mv	s2,a0
    80001de6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001de8:	c129                	beqz	a0,80001e2a <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001dea:	07000613          	li	a2,112
    80001dee:	4581                	li	a1,0
    80001df0:	06048513          	addi	a0,s1,96
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	062080e7          	jalr	98(ra) # 80000e56 <memset>
  p->context.ra = (uint64)forkret;
    80001dfc:	00000797          	auipc	a5,0x0
    80001e00:	db478793          	addi	a5,a5,-588 # 80001bb0 <forkret>
    80001e04:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e06:	60bc                	ld	a5,64(s1)
    80001e08:	6705                	lui	a4,0x1
    80001e0a:	97ba                	add	a5,a5,a4
    80001e0c:	f4bc                	sd	a5,104(s1)
}
    80001e0e:	8526                	mv	a0,s1
    80001e10:	60e2                	ld	ra,24(sp)
    80001e12:	6442                	ld	s0,16(sp)
    80001e14:	64a2                	ld	s1,8(sp)
    80001e16:	6902                	ld	s2,0(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret
    release(&p->lock);
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	ff0080e7          	jalr	-16(ra) # 80000e0e <release>
    return 0;
    80001e26:	84ca                	mv	s1,s2
    80001e28:	b7dd                	j	80001e0e <allocproc+0x8c>
    freeproc(p);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	efe080e7          	jalr	-258(ra) # 80001d2a <freeproc>
    release(&p->lock);
    80001e34:	8526                	mv	a0,s1
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	fd8080e7          	jalr	-40(ra) # 80000e0e <release>
    return 0;
    80001e3e:	84ca                	mv	s1,s2
    80001e40:	b7f9                	j	80001e0e <allocproc+0x8c>

0000000080001e42 <userinit>:
{
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	f36080e7          	jalr	-202(ra) # 80001d82 <allocproc>
    80001e54:	84aa                	mv	s1,a0
  initproc = p;
    80001e56:	00007797          	auipc	a5,0x7
    80001e5a:	1ca7b123          	sd	a0,450(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e5e:	03400613          	li	a2,52
    80001e62:	00007597          	auipc	a1,0x7
    80001e66:	a1e58593          	addi	a1,a1,-1506 # 80008880 <initcode>
    80001e6a:	6928                	ld	a0,80(a0)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	6a6080e7          	jalr	1702(ra) # 80001512 <uvminit>
  p->sz = PGSIZE;
    80001e74:	6785                	lui	a5,0x1
    80001e76:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e78:	6cb8                	ld	a4,88(s1)
    80001e7a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e7e:	6cb8                	ld	a4,88(s1)
    80001e80:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	00006597          	auipc	a1,0x6
    80001e88:	3ac58593          	addi	a1,a1,940 # 80008230 <digits+0x1f0>
    80001e8c:	15848513          	addi	a0,s1,344
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	11c080e7          	jalr	284(ra) # 80000fac <safestrcpy>
  p->cwd = namei("/");
    80001e98:	00006517          	auipc	a0,0x6
    80001e9c:	3a850513          	addi	a0,a0,936 # 80008240 <digits+0x200>
    80001ea0:	00002097          	auipc	ra,0x2
    80001ea4:	17c080e7          	jalr	380(ra) # 8000401c <namei>
    80001ea8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eac:	4789                	li	a5,2
    80001eae:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	f5c080e7          	jalr	-164(ra) # 80000e0e <release>
}
    80001eba:	60e2                	ld	ra,24(sp)
    80001ebc:	6442                	ld	s0,16(sp)
    80001ebe:	64a2                	ld	s1,8(sp)
    80001ec0:	6105                	addi	sp,sp,32
    80001ec2:	8082                	ret

0000000080001ec4 <growproc>:
{
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	e04a                	sd	s2,0(sp)
    80001ece:	1000                	addi	s0,sp,32
    80001ed0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	ca6080e7          	jalr	-858(ra) # 80001b78 <myproc>
    80001eda:	892a                	mv	s2,a0
  sz = p->sz;
    80001edc:	652c                	ld	a1,72(a0)
    80001ede:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ee2:	00904f63          	bgtz	s1,80001f00 <growproc+0x3c>
  } else if(n < 0){
    80001ee6:	0204cc63          	bltz	s1,80001f1e <growproc+0x5a>
  p->sz = sz;
    80001eea:	1602                	slli	a2,a2,0x20
    80001eec:	9201                	srli	a2,a2,0x20
    80001eee:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ef2:	4501                	li	a0,0
}
    80001ef4:	60e2                	ld	ra,24(sp)
    80001ef6:	6442                	ld	s0,16(sp)
    80001ef8:	64a2                	ld	s1,8(sp)
    80001efa:	6902                	ld	s2,0(sp)
    80001efc:	6105                	addi	sp,sp,32
    80001efe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f00:	9e25                	addw	a2,a2,s1
    80001f02:	1602                	slli	a2,a2,0x20
    80001f04:	9201                	srli	a2,a2,0x20
    80001f06:	1582                	slli	a1,a1,0x20
    80001f08:	9181                	srli	a1,a1,0x20
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	6c0080e7          	jalr	1728(ra) # 800015cc <uvmalloc>
    80001f14:	0005061b          	sext.w	a2,a0
    80001f18:	fa69                	bnez	a2,80001eea <growproc+0x26>
      return -1;
    80001f1a:	557d                	li	a0,-1
    80001f1c:	bfe1                	j	80001ef4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f1e:	9e25                	addw	a2,a2,s1
    80001f20:	1602                	slli	a2,a2,0x20
    80001f22:	9201                	srli	a2,a2,0x20
    80001f24:	1582                	slli	a1,a1,0x20
    80001f26:	9181                	srli	a1,a1,0x20
    80001f28:	6928                	ld	a0,80(a0)
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	65a080e7          	jalr	1626(ra) # 80001584 <uvmdealloc>
    80001f32:	0005061b          	sext.w	a2,a0
    80001f36:	bf55                	j	80001eea <growproc+0x26>

0000000080001f38 <fork>:
{
    80001f38:	7179                	addi	sp,sp,-48
    80001f3a:	f406                	sd	ra,40(sp)
    80001f3c:	f022                	sd	s0,32(sp)
    80001f3e:	ec26                	sd	s1,24(sp)
    80001f40:	e84a                	sd	s2,16(sp)
    80001f42:	e44e                	sd	s3,8(sp)
    80001f44:	e052                	sd	s4,0(sp)
    80001f46:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	c30080e7          	jalr	-976(ra) # 80001b78 <myproc>
    80001f50:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	e30080e7          	jalr	-464(ra) # 80001d82 <allocproc>
    80001f5a:	c175                	beqz	a0,8000203e <fork+0x106>
    80001f5c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f5e:	04893603          	ld	a2,72(s2)
    80001f62:	692c                	ld	a1,80(a0)
    80001f64:	05093503          	ld	a0,80(s2)
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	7b0080e7          	jalr	1968(ra) # 80001718 <uvmcopy>
    80001f70:	04054863          	bltz	a0,80001fc0 <fork+0x88>
  np->sz = p->sz;
    80001f74:	04893783          	ld	a5,72(s2)
    80001f78:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f7c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f80:	05893683          	ld	a3,88(s2)
    80001f84:	87b6                	mv	a5,a3
    80001f86:	0589b703          	ld	a4,88(s3)
    80001f8a:	12068693          	addi	a3,a3,288
    80001f8e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f92:	6788                	ld	a0,8(a5)
    80001f94:	6b8c                	ld	a1,16(a5)
    80001f96:	6f90                	ld	a2,24(a5)
    80001f98:	01073023          	sd	a6,0(a4)
    80001f9c:	e708                	sd	a0,8(a4)
    80001f9e:	eb0c                	sd	a1,16(a4)
    80001fa0:	ef10                	sd	a2,24(a4)
    80001fa2:	02078793          	addi	a5,a5,32
    80001fa6:	02070713          	addi	a4,a4,32
    80001faa:	fed792e3          	bne	a5,a3,80001f8e <fork+0x56>
  np->trapframe->a0 = 0;
    80001fae:	0589b783          	ld	a5,88(s3)
    80001fb2:	0607b823          	sd	zero,112(a5)
    80001fb6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fba:	15000a13          	li	s4,336
    80001fbe:	a03d                	j	80001fec <fork+0xb4>
    freeproc(np);
    80001fc0:	854e                	mv	a0,s3
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	d68080e7          	jalr	-664(ra) # 80001d2a <freeproc>
    release(&np->lock);
    80001fca:	854e                	mv	a0,s3
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	e42080e7          	jalr	-446(ra) # 80000e0e <release>
    return -1;
    80001fd4:	54fd                	li	s1,-1
    80001fd6:	a899                	j	8000202c <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fd8:	00002097          	auipc	ra,0x2
    80001fdc:	6d0080e7          	jalr	1744(ra) # 800046a8 <filedup>
    80001fe0:	009987b3          	add	a5,s3,s1
    80001fe4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fe6:	04a1                	addi	s1,s1,8
    80001fe8:	01448763          	beq	s1,s4,80001ff6 <fork+0xbe>
    if(p->ofile[i])
    80001fec:	009907b3          	add	a5,s2,s1
    80001ff0:	6388                	ld	a0,0(a5)
    80001ff2:	f17d                	bnez	a0,80001fd8 <fork+0xa0>
    80001ff4:	bfcd                	j	80001fe6 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ff6:	15093503          	ld	a0,336(s2)
    80001ffa:	00002097          	auipc	ra,0x2
    80001ffe:	830080e7          	jalr	-2000(ra) # 8000382a <idup>
    80002002:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002006:	4641                	li	a2,16
    80002008:	15890593          	addi	a1,s2,344
    8000200c:	15898513          	addi	a0,s3,344
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	f9c080e7          	jalr	-100(ra) # 80000fac <safestrcpy>
  pid = np->pid;
    80002018:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    8000201c:	4789                	li	a5,2
    8000201e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002022:	854e                	mv	a0,s3
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	dea080e7          	jalr	-534(ra) # 80000e0e <release>
}
    8000202c:	8526                	mv	a0,s1
    8000202e:	70a2                	ld	ra,40(sp)
    80002030:	7402                	ld	s0,32(sp)
    80002032:	64e2                	ld	s1,24(sp)
    80002034:	6942                	ld	s2,16(sp)
    80002036:	69a2                	ld	s3,8(sp)
    80002038:	6a02                	ld	s4,0(sp)
    8000203a:	6145                	addi	sp,sp,48
    8000203c:	8082                	ret
    return -1;
    8000203e:	54fd                	li	s1,-1
    80002040:	b7f5                	j	8000202c <fork+0xf4>

0000000080002042 <reparent>:
{
    80002042:	7179                	addi	sp,sp,-48
    80002044:	f406                	sd	ra,40(sp)
    80002046:	f022                	sd	s0,32(sp)
    80002048:	ec26                	sd	s1,24(sp)
    8000204a:	e84a                	sd	s2,16(sp)
    8000204c:	e44e                	sd	s3,8(sp)
    8000204e:	e052                	sd	s4,0(sp)
    80002050:	1800                	addi	s0,sp,48
    80002052:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002054:	00230497          	auipc	s1,0x230
    80002058:	d1448493          	addi	s1,s1,-748 # 80231d68 <proc>
      pp->parent = initproc;
    8000205c:	00007a17          	auipc	s4,0x7
    80002060:	fbca0a13          	addi	s4,s4,-68 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002064:	00235997          	auipc	s3,0x235
    80002068:	70498993          	addi	s3,s3,1796 # 80237768 <tickslock>
    8000206c:	a029                	j	80002076 <reparent+0x34>
    8000206e:	16848493          	addi	s1,s1,360
    80002072:	03348363          	beq	s1,s3,80002098 <reparent+0x56>
    if(pp->parent == p){
    80002076:	709c                	ld	a5,32(s1)
    80002078:	ff279be3          	bne	a5,s2,8000206e <reparent+0x2c>
      acquire(&pp->lock);
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	cdc080e7          	jalr	-804(ra) # 80000d5a <acquire>
      pp->parent = initproc;
    80002086:	000a3783          	ld	a5,0(s4)
    8000208a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	d80080e7          	jalr	-640(ra) # 80000e0e <release>
    80002096:	bfe1                	j	8000206e <reparent+0x2c>
}
    80002098:	70a2                	ld	ra,40(sp)
    8000209a:	7402                	ld	s0,32(sp)
    8000209c:	64e2                	ld	s1,24(sp)
    8000209e:	6942                	ld	s2,16(sp)
    800020a0:	69a2                	ld	s3,8(sp)
    800020a2:	6a02                	ld	s4,0(sp)
    800020a4:	6145                	addi	sp,sp,48
    800020a6:	8082                	ret

00000000800020a8 <scheduler>:
{
    800020a8:	711d                	addi	sp,sp,-96
    800020aa:	ec86                	sd	ra,88(sp)
    800020ac:	e8a2                	sd	s0,80(sp)
    800020ae:	e4a6                	sd	s1,72(sp)
    800020b0:	e0ca                	sd	s2,64(sp)
    800020b2:	fc4e                	sd	s3,56(sp)
    800020b4:	f852                	sd	s4,48(sp)
    800020b6:	f456                	sd	s5,40(sp)
    800020b8:	f05a                	sd	s6,32(sp)
    800020ba:	ec5e                	sd	s7,24(sp)
    800020bc:	e862                	sd	s8,16(sp)
    800020be:	e466                	sd	s9,8(sp)
    800020c0:	1080                	addi	s0,sp,96
    800020c2:	8792                	mv	a5,tp
  int id = r_tp();
    800020c4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020c6:	00779c13          	slli	s8,a5,0x7
    800020ca:	00230717          	auipc	a4,0x230
    800020ce:	88670713          	addi	a4,a4,-1914 # 80231950 <pid_lock>
    800020d2:	9762                	add	a4,a4,s8
    800020d4:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800020d8:	00230717          	auipc	a4,0x230
    800020dc:	89870713          	addi	a4,a4,-1896 # 80231970 <cpus+0x8>
    800020e0:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800020e2:	4a89                	li	s5,2
        c->proc = p;
    800020e4:	079e                	slli	a5,a5,0x7
    800020e6:	00230b17          	auipc	s6,0x230
    800020ea:	86ab0b13          	addi	s6,s6,-1942 # 80231950 <pid_lock>
    800020ee:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020f0:	00235a17          	auipc	s4,0x235
    800020f4:	678a0a13          	addi	s4,s4,1656 # 80237768 <tickslock>
    int nproc = 0;
    800020f8:	4c81                	li	s9,0
    800020fa:	a8a1                	j	80002152 <scheduler+0xaa>
        p->state = RUNNING;
    800020fc:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002100:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002104:	06048593          	addi	a1,s1,96
    80002108:	8562                	mv	a0,s8
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	63a080e7          	jalr	1594(ra) # 80002744 <swtch>
        c->proc = 0;
    80002112:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	cf6080e7          	jalr	-778(ra) # 80000e0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002120:	16848493          	addi	s1,s1,360
    80002124:	01448d63          	beq	s1,s4,8000213e <scheduler+0x96>
      acquire(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	c30080e7          	jalr	-976(ra) # 80000d5a <acquire>
      if(p->state != UNUSED) {
    80002132:	4c9c                	lw	a5,24(s1)
    80002134:	d3ed                	beqz	a5,80002116 <scheduler+0x6e>
        nproc++;
    80002136:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002138:	fd579fe3          	bne	a5,s5,80002116 <scheduler+0x6e>
    8000213c:	b7c1                	j	800020fc <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000213e:	013aca63          	blt	s5,s3,80002152 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002142:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002146:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000214a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000214e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002152:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002156:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000215a:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000215e:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002160:	00230497          	auipc	s1,0x230
    80002164:	c0848493          	addi	s1,s1,-1016 # 80231d68 <proc>
        p->state = RUNNING;
    80002168:	4b8d                	li	s7,3
    8000216a:	bf7d                	j	80002128 <scheduler+0x80>

000000008000216c <sched>:
{
    8000216c:	7179                	addi	sp,sp,-48
    8000216e:	f406                	sd	ra,40(sp)
    80002170:	f022                	sd	s0,32(sp)
    80002172:	ec26                	sd	s1,24(sp)
    80002174:	e84a                	sd	s2,16(sp)
    80002176:	e44e                	sd	s3,8(sp)
    80002178:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	9fe080e7          	jalr	-1538(ra) # 80001b78 <myproc>
    80002182:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b5c080e7          	jalr	-1188(ra) # 80000ce0 <holding>
    8000218c:	c93d                	beqz	a0,80002202 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	0022f717          	auipc	a4,0x22f
    80002198:	7bc70713          	addi	a4,a4,1980 # 80231950 <pid_lock>
    8000219c:	97ba                	add	a5,a5,a4
    8000219e:	0907a703          	lw	a4,144(a5)
    800021a2:	4785                	li	a5,1
    800021a4:	06f71763          	bne	a4,a5,80002212 <sched+0xa6>
  if(p->state == RUNNING)
    800021a8:	4c98                	lw	a4,24(s1)
    800021aa:	478d                	li	a5,3
    800021ac:	06f70b63          	beq	a4,a5,80002222 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021b4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021b6:	efb5                	bnez	a5,80002232 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ba:	0022f917          	auipc	s2,0x22f
    800021be:	79690913          	addi	s2,s2,1942 # 80231950 <pid_lock>
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
    800021c6:	97ca                	add	a5,a5,s2
    800021c8:	0947a983          	lw	s3,148(a5)
    800021cc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021ce:	2781                	sext.w	a5,a5
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	0022f597          	auipc	a1,0x22f
    800021d6:	79e58593          	addi	a1,a1,1950 # 80231970 <cpus+0x8>
    800021da:	95be                	add	a1,a1,a5
    800021dc:	06048513          	addi	a0,s1,96
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	564080e7          	jalr	1380(ra) # 80002744 <swtch>
    800021e8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	97ca                	add	a5,a5,s2
    800021f0:	0937aa23          	sw	s3,148(a5)
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret
    panic("sched p->lock");
    80002202:	00006517          	auipc	a0,0x6
    80002206:	04650513          	addi	a0,a0,70 # 80008248 <digits+0x208>
    8000220a:	ffffe097          	auipc	ra,0xffffe
    8000220e:	33e080e7          	jalr	830(ra) # 80000548 <panic>
    panic("sched locks");
    80002212:	00006517          	auipc	a0,0x6
    80002216:	04650513          	addi	a0,a0,70 # 80008258 <digits+0x218>
    8000221a:	ffffe097          	auipc	ra,0xffffe
    8000221e:	32e080e7          	jalr	814(ra) # 80000548 <panic>
    panic("sched running");
    80002222:	00006517          	auipc	a0,0x6
    80002226:	04650513          	addi	a0,a0,70 # 80008268 <digits+0x228>
    8000222a:	ffffe097          	auipc	ra,0xffffe
    8000222e:	31e080e7          	jalr	798(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002232:	00006517          	auipc	a0,0x6
    80002236:	04650513          	addi	a0,a0,70 # 80008278 <digits+0x238>
    8000223a:	ffffe097          	auipc	ra,0xffffe
    8000223e:	30e080e7          	jalr	782(ra) # 80000548 <panic>

0000000080002242 <exit>:
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	e052                	sd	s4,0(sp)
    80002250:	1800                	addi	s0,sp,48
    80002252:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002254:	00000097          	auipc	ra,0x0
    80002258:	924080e7          	jalr	-1756(ra) # 80001b78 <myproc>
    8000225c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000225e:	00007797          	auipc	a5,0x7
    80002262:	dba7b783          	ld	a5,-582(a5) # 80009018 <initproc>
    80002266:	0d050493          	addi	s1,a0,208
    8000226a:	15050913          	addi	s2,a0,336
    8000226e:	02a79363          	bne	a5,a0,80002294 <exit+0x52>
    panic("init exiting");
    80002272:	00006517          	auipc	a0,0x6
    80002276:	01e50513          	addi	a0,a0,30 # 80008290 <digits+0x250>
    8000227a:	ffffe097          	auipc	ra,0xffffe
    8000227e:	2ce080e7          	jalr	718(ra) # 80000548 <panic>
      fileclose(f);
    80002282:	00002097          	auipc	ra,0x2
    80002286:	478080e7          	jalr	1144(ra) # 800046fa <fileclose>
      p->ofile[fd] = 0;
    8000228a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000228e:	04a1                	addi	s1,s1,8
    80002290:	01248563          	beq	s1,s2,8000229a <exit+0x58>
    if(p->ofile[fd]){
    80002294:	6088                	ld	a0,0(s1)
    80002296:	f575                	bnez	a0,80002282 <exit+0x40>
    80002298:	bfdd                	j	8000228e <exit+0x4c>
  begin_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	f8e080e7          	jalr	-114(ra) # 80004228 <begin_op>
  iput(p->cwd);
    800022a2:	1509b503          	ld	a0,336(s3)
    800022a6:	00001097          	auipc	ra,0x1
    800022aa:	77c080e7          	jalr	1916(ra) # 80003a22 <iput>
  end_op();
    800022ae:	00002097          	auipc	ra,0x2
    800022b2:	ffa080e7          	jalr	-6(ra) # 800042a8 <end_op>
  p->cwd = 0;
    800022b6:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022ba:	00007497          	auipc	s1,0x7
    800022be:	d5e48493          	addi	s1,s1,-674 # 80009018 <initproc>
    800022c2:	6088                	ld	a0,0(s1)
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	a96080e7          	jalr	-1386(ra) # 80000d5a <acquire>
  wakeup1(initproc);
    800022cc:	6088                	ld	a0,0(s1)
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	76a080e7          	jalr	1898(ra) # 80001a38 <wakeup1>
  release(&initproc->lock);
    800022d6:	6088                	ld	a0,0(s1)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	b36080e7          	jalr	-1226(ra) # 80000e0e <release>
  acquire(&p->lock);
    800022e0:	854e                	mv	a0,s3
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	a78080e7          	jalr	-1416(ra) # 80000d5a <acquire>
  struct proc *original_parent = p->parent;
    800022ea:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800022ee:	854e                	mv	a0,s3
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	b1e080e7          	jalr	-1250(ra) # 80000e0e <release>
  acquire(&original_parent->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	a60080e7          	jalr	-1440(ra) # 80000d5a <acquire>
  acquire(&p->lock);
    80002302:	854e                	mv	a0,s3
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	a56080e7          	jalr	-1450(ra) # 80000d5a <acquire>
  reparent(p);
    8000230c:	854e                	mv	a0,s3
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	d34080e7          	jalr	-716(ra) # 80002042 <reparent>
  wakeup1(original_parent);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	720080e7          	jalr	1824(ra) # 80001a38 <wakeup1>
  p->xstate = status;
    80002320:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002324:	4791                	li	a5,4
    80002326:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	ae2080e7          	jalr	-1310(ra) # 80000e0e <release>
  sched();
    80002334:	00000097          	auipc	ra,0x0
    80002338:	e38080e7          	jalr	-456(ra) # 8000216c <sched>
  panic("zombie exit");
    8000233c:	00006517          	auipc	a0,0x6
    80002340:	f6450513          	addi	a0,a0,-156 # 800082a0 <digits+0x260>
    80002344:	ffffe097          	auipc	ra,0xffffe
    80002348:	204080e7          	jalr	516(ra) # 80000548 <panic>

000000008000234c <yield>:
{
    8000234c:	1101                	addi	sp,sp,-32
    8000234e:	ec06                	sd	ra,24(sp)
    80002350:	e822                	sd	s0,16(sp)
    80002352:	e426                	sd	s1,8(sp)
    80002354:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	822080e7          	jalr	-2014(ra) # 80001b78 <myproc>
    8000235e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	9fa080e7          	jalr	-1542(ra) # 80000d5a <acquire>
  p->state = RUNNABLE;
    80002368:	4789                	li	a5,2
    8000236a:	cc9c                	sw	a5,24(s1)
  sched();
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	e00080e7          	jalr	-512(ra) # 8000216c <sched>
  release(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	a98080e7          	jalr	-1384(ra) # 80000e0e <release>
}
    8000237e:	60e2                	ld	ra,24(sp)
    80002380:	6442                	ld	s0,16(sp)
    80002382:	64a2                	ld	s1,8(sp)
    80002384:	6105                	addi	sp,sp,32
    80002386:	8082                	ret

0000000080002388 <sleep>:
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	89aa                	mv	s3,a0
    80002398:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	7de080e7          	jalr	2014(ra) # 80001b78 <myproc>
    800023a2:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800023a4:	05250663          	beq	a0,s2,800023f0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	9b2080e7          	jalr	-1614(ra) # 80000d5a <acquire>
    release(lk);
    800023b0:	854a                	mv	a0,s2
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	a5c080e7          	jalr	-1444(ra) # 80000e0e <release>
  p->chan = chan;
    800023ba:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800023be:	4785                	li	a5,1
    800023c0:	cc9c                	sw	a5,24(s1)
  sched();
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	daa080e7          	jalr	-598(ra) # 8000216c <sched>
  p->chan = 0;
    800023ca:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	a3e080e7          	jalr	-1474(ra) # 80000e0e <release>
    acquire(lk);
    800023d8:	854a                	mv	a0,s2
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	980080e7          	jalr	-1664(ra) # 80000d5a <acquire>
}
    800023e2:	70a2                	ld	ra,40(sp)
    800023e4:	7402                	ld	s0,32(sp)
    800023e6:	64e2                	ld	s1,24(sp)
    800023e8:	6942                	ld	s2,16(sp)
    800023ea:	69a2                	ld	s3,8(sp)
    800023ec:	6145                	addi	sp,sp,48
    800023ee:	8082                	ret
  p->chan = chan;
    800023f0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800023f4:	4785                	li	a5,1
    800023f6:	cd1c                	sw	a5,24(a0)
  sched();
    800023f8:	00000097          	auipc	ra,0x0
    800023fc:	d74080e7          	jalr	-652(ra) # 8000216c <sched>
  p->chan = 0;
    80002400:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002404:	bff9                	j	800023e2 <sleep+0x5a>

0000000080002406 <wait>:
{
    80002406:	715d                	addi	sp,sp,-80
    80002408:	e486                	sd	ra,72(sp)
    8000240a:	e0a2                	sd	s0,64(sp)
    8000240c:	fc26                	sd	s1,56(sp)
    8000240e:	f84a                	sd	s2,48(sp)
    80002410:	f44e                	sd	s3,40(sp)
    80002412:	f052                	sd	s4,32(sp)
    80002414:	ec56                	sd	s5,24(sp)
    80002416:	e85a                	sd	s6,16(sp)
    80002418:	e45e                	sd	s7,8(sp)
    8000241a:	e062                	sd	s8,0(sp)
    8000241c:	0880                	addi	s0,sp,80
    8000241e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	758080e7          	jalr	1880(ra) # 80001b78 <myproc>
    80002428:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000242a:	8c2a                	mv	s8,a0
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	92e080e7          	jalr	-1746(ra) # 80000d5a <acquire>
    havekids = 0;
    80002434:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002436:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002438:	00235997          	auipc	s3,0x235
    8000243c:	33098993          	addi	s3,s3,816 # 80237768 <tickslock>
        havekids = 1;
    80002440:	4a85                	li	s5,1
    havekids = 0;
    80002442:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002444:	00230497          	auipc	s1,0x230
    80002448:	92448493          	addi	s1,s1,-1756 # 80231d68 <proc>
    8000244c:	a08d                	j	800024ae <wait+0xa8>
          pid = np->pid;
    8000244e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002452:	000b0e63          	beqz	s6,8000246e <wait+0x68>
    80002456:	4691                	li	a3,4
    80002458:	03448613          	addi	a2,s1,52
    8000245c:	85da                	mv	a1,s6
    8000245e:	05093503          	ld	a0,80(s2)
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	3a6080e7          	jalr	934(ra) # 80001808 <copyout>
    8000246a:	02054263          	bltz	a0,8000248e <wait+0x88>
          freeproc(np);
    8000246e:	8526                	mv	a0,s1
    80002470:	00000097          	auipc	ra,0x0
    80002474:	8ba080e7          	jalr	-1862(ra) # 80001d2a <freeproc>
          release(&np->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	994080e7          	jalr	-1644(ra) # 80000e0e <release>
          release(&p->lock);
    80002482:	854a                	mv	a0,s2
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	98a080e7          	jalr	-1654(ra) # 80000e0e <release>
          return pid;
    8000248c:	a8a9                	j	800024e6 <wait+0xe0>
            release(&np->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	97e080e7          	jalr	-1666(ra) # 80000e0e <release>
            release(&p->lock);
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	974080e7          	jalr	-1676(ra) # 80000e0e <release>
            return -1;
    800024a2:	59fd                	li	s3,-1
    800024a4:	a089                	j	800024e6 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800024a6:	16848493          	addi	s1,s1,360
    800024aa:	03348463          	beq	s1,s3,800024d2 <wait+0xcc>
      if(np->parent == p){
    800024ae:	709c                	ld	a5,32(s1)
    800024b0:	ff279be3          	bne	a5,s2,800024a6 <wait+0xa0>
        acquire(&np->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	8a4080e7          	jalr	-1884(ra) # 80000d5a <acquire>
        if(np->state == ZOMBIE){
    800024be:	4c9c                	lw	a5,24(s1)
    800024c0:	f94787e3          	beq	a5,s4,8000244e <wait+0x48>
        release(&np->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	948080e7          	jalr	-1720(ra) # 80000e0e <release>
        havekids = 1;
    800024ce:	8756                	mv	a4,s5
    800024d0:	bfd9                	j	800024a6 <wait+0xa0>
    if(!havekids || p->killed){
    800024d2:	c701                	beqz	a4,800024da <wait+0xd4>
    800024d4:	03092783          	lw	a5,48(s2)
    800024d8:	c785                	beqz	a5,80002500 <wait+0xfa>
      release(&p->lock);
    800024da:	854a                	mv	a0,s2
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	932080e7          	jalr	-1742(ra) # 80000e0e <release>
      return -1;
    800024e4:	59fd                	li	s3,-1
}
    800024e6:	854e                	mv	a0,s3
    800024e8:	60a6                	ld	ra,72(sp)
    800024ea:	6406                	ld	s0,64(sp)
    800024ec:	74e2                	ld	s1,56(sp)
    800024ee:	7942                	ld	s2,48(sp)
    800024f0:	79a2                	ld	s3,40(sp)
    800024f2:	7a02                	ld	s4,32(sp)
    800024f4:	6ae2                	ld	s5,24(sp)
    800024f6:	6b42                	ld	s6,16(sp)
    800024f8:	6ba2                	ld	s7,8(sp)
    800024fa:	6c02                	ld	s8,0(sp)
    800024fc:	6161                	addi	sp,sp,80
    800024fe:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002500:	85e2                	mv	a1,s8
    80002502:	854a                	mv	a0,s2
    80002504:	00000097          	auipc	ra,0x0
    80002508:	e84080e7          	jalr	-380(ra) # 80002388 <sleep>
    havekids = 0;
    8000250c:	bf1d                	j	80002442 <wait+0x3c>

000000008000250e <wakeup>:
{
    8000250e:	7139                	addi	sp,sp,-64
    80002510:	fc06                	sd	ra,56(sp)
    80002512:	f822                	sd	s0,48(sp)
    80002514:	f426                	sd	s1,40(sp)
    80002516:	f04a                	sd	s2,32(sp)
    80002518:	ec4e                	sd	s3,24(sp)
    8000251a:	e852                	sd	s4,16(sp)
    8000251c:	e456                	sd	s5,8(sp)
    8000251e:	0080                	addi	s0,sp,64
    80002520:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002522:	00230497          	auipc	s1,0x230
    80002526:	84648493          	addi	s1,s1,-1978 # 80231d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000252a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000252c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000252e:	00235917          	auipc	s2,0x235
    80002532:	23a90913          	addi	s2,s2,570 # 80237768 <tickslock>
    80002536:	a821                	j	8000254e <wakeup+0x40>
      p->state = RUNNABLE;
    80002538:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	8d0080e7          	jalr	-1840(ra) # 80000e0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002546:	16848493          	addi	s1,s1,360
    8000254a:	01248e63          	beq	s1,s2,80002566 <wakeup+0x58>
    acquire(&p->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	80a080e7          	jalr	-2038(ra) # 80000d5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002558:	4c9c                	lw	a5,24(s1)
    8000255a:	ff3791e3          	bne	a5,s3,8000253c <wakeup+0x2e>
    8000255e:	749c                	ld	a5,40(s1)
    80002560:	fd479ee3          	bne	a5,s4,8000253c <wakeup+0x2e>
    80002564:	bfd1                	j	80002538 <wakeup+0x2a>
}
    80002566:	70e2                	ld	ra,56(sp)
    80002568:	7442                	ld	s0,48(sp)
    8000256a:	74a2                	ld	s1,40(sp)
    8000256c:	7902                	ld	s2,32(sp)
    8000256e:	69e2                	ld	s3,24(sp)
    80002570:	6a42                	ld	s4,16(sp)
    80002572:	6aa2                	ld	s5,8(sp)
    80002574:	6121                	addi	sp,sp,64
    80002576:	8082                	ret

0000000080002578 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	1800                	addi	s0,sp,48
    80002586:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002588:	0022f497          	auipc	s1,0x22f
    8000258c:	7e048493          	addi	s1,s1,2016 # 80231d68 <proc>
    80002590:	00235997          	auipc	s3,0x235
    80002594:	1d898993          	addi	s3,s3,472 # 80237768 <tickslock>
    acquire(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	7c0080e7          	jalr	1984(ra) # 80000d5a <acquire>
    if(p->pid == pid){
    800025a2:	5c9c                	lw	a5,56(s1)
    800025a4:	01278d63          	beq	a5,s2,800025be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	864080e7          	jalr	-1948(ra) # 80000e0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b2:	16848493          	addi	s1,s1,360
    800025b6:	ff3491e3          	bne	s1,s3,80002598 <kill+0x20>
  }
  return -1;
    800025ba:	557d                	li	a0,-1
    800025bc:	a829                	j	800025d6 <kill+0x5e>
      p->killed = 1;
    800025be:	4785                	li	a5,1
    800025c0:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800025c2:	4c98                	lw	a4,24(s1)
    800025c4:	4785                	li	a5,1
    800025c6:	00f70f63          	beq	a4,a5,800025e4 <kill+0x6c>
      release(&p->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	842080e7          	jalr	-1982(ra) # 80000e0e <release>
      return 0;
    800025d4:	4501                	li	a0,0
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret
        p->state = RUNNABLE;
    800025e4:	4789                	li	a5,2
    800025e6:	cc9c                	sw	a5,24(s1)
    800025e8:	b7cd                	j	800025ca <kill+0x52>

00000000800025ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025ea:	7179                	addi	sp,sp,-48
    800025ec:	f406                	sd	ra,40(sp)
    800025ee:	f022                	sd	s0,32(sp)
    800025f0:	ec26                	sd	s1,24(sp)
    800025f2:	e84a                	sd	s2,16(sp)
    800025f4:	e44e                	sd	s3,8(sp)
    800025f6:	e052                	sd	s4,0(sp)
    800025f8:	1800                	addi	s0,sp,48
    800025fa:	84aa                	mv	s1,a0
    800025fc:	892e                	mv	s2,a1
    800025fe:	89b2                	mv	s3,a2
    80002600:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	576080e7          	jalr	1398(ra) # 80001b78 <myproc>
  if(user_dst){
    8000260a:	c08d                	beqz	s1,8000262c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000260c:	86d2                	mv	a3,s4
    8000260e:	864e                	mv	a2,s3
    80002610:	85ca                	mv	a1,s2
    80002612:	6928                	ld	a0,80(a0)
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	1f4080e7          	jalr	500(ra) # 80001808 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000261c:	70a2                	ld	ra,40(sp)
    8000261e:	7402                	ld	s0,32(sp)
    80002620:	64e2                	ld	s1,24(sp)
    80002622:	6942                	ld	s2,16(sp)
    80002624:	69a2                	ld	s3,8(sp)
    80002626:	6a02                	ld	s4,0(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret
    memmove((char *)dst, src, len);
    8000262c:	000a061b          	sext.w	a2,s4
    80002630:	85ce                	mv	a1,s3
    80002632:	854a                	mv	a0,s2
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	882080e7          	jalr	-1918(ra) # 80000eb6 <memmove>
    return 0;
    8000263c:	8526                	mv	a0,s1
    8000263e:	bff9                	j	8000261c <either_copyout+0x32>

0000000080002640 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002640:	7179                	addi	sp,sp,-48
    80002642:	f406                	sd	ra,40(sp)
    80002644:	f022                	sd	s0,32(sp)
    80002646:	ec26                	sd	s1,24(sp)
    80002648:	e84a                	sd	s2,16(sp)
    8000264a:	e44e                	sd	s3,8(sp)
    8000264c:	e052                	sd	s4,0(sp)
    8000264e:	1800                	addi	s0,sp,48
    80002650:	892a                	mv	s2,a0
    80002652:	84ae                	mv	s1,a1
    80002654:	89b2                	mv	s3,a2
    80002656:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002658:	fffff097          	auipc	ra,0xfffff
    8000265c:	520080e7          	jalr	1312(ra) # 80001b78 <myproc>
  if(user_src){
    80002660:	c08d                	beqz	s1,80002682 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002662:	86d2                	mv	a3,s4
    80002664:	864e                	mv	a2,s3
    80002666:	85ca                	mv	a1,s2
    80002668:	6928                	ld	a0,80(a0)
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	28e080e7          	jalr	654(ra) # 800018f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002672:	70a2                	ld	ra,40(sp)
    80002674:	7402                	ld	s0,32(sp)
    80002676:	64e2                	ld	s1,24(sp)
    80002678:	6942                	ld	s2,16(sp)
    8000267a:	69a2                	ld	s3,8(sp)
    8000267c:	6a02                	ld	s4,0(sp)
    8000267e:	6145                	addi	sp,sp,48
    80002680:	8082                	ret
    memmove(dst, (char*)src, len);
    80002682:	000a061b          	sext.w	a2,s4
    80002686:	85ce                	mv	a1,s3
    80002688:	854a                	mv	a0,s2
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	82c080e7          	jalr	-2004(ra) # 80000eb6 <memmove>
    return 0;
    80002692:	8526                	mv	a0,s1
    80002694:	bff9                	j	80002672 <either_copyin+0x32>

0000000080002696 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002696:	715d                	addi	sp,sp,-80
    80002698:	e486                	sd	ra,72(sp)
    8000269a:	e0a2                	sd	s0,64(sp)
    8000269c:	fc26                	sd	s1,56(sp)
    8000269e:	f84a                	sd	s2,48(sp)
    800026a0:	f44e                	sd	s3,40(sp)
    800026a2:	f052                	sd	s4,32(sp)
    800026a4:	ec56                	sd	s5,24(sp)
    800026a6:	e85a                	sd	s6,16(sp)
    800026a8:	e45e                	sd	s7,8(sp)
    800026aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026ac:	00006517          	auipc	a0,0x6
    800026b0:	a4450513          	addi	a0,a0,-1468 # 800080f0 <digits+0xb0>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	ede080e7          	jalr	-290(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026bc:	00230497          	auipc	s1,0x230
    800026c0:	80448493          	addi	s1,s1,-2044 # 80231ec0 <proc+0x158>
    800026c4:	00235917          	auipc	s2,0x235
    800026c8:	1fc90913          	addi	s2,s2,508 # 802378c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026cc:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026ce:	00006997          	auipc	s3,0x6
    800026d2:	be298993          	addi	s3,s3,-1054 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800026d6:	00006a97          	auipc	s5,0x6
    800026da:	be2a8a93          	addi	s5,s5,-1054 # 800082b8 <digits+0x278>
    printf("\n");
    800026de:	00006a17          	auipc	s4,0x6
    800026e2:	a12a0a13          	addi	s4,s4,-1518 # 800080f0 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e6:	00006b97          	auipc	s7,0x6
    800026ea:	c0ab8b93          	addi	s7,s7,-1014 # 800082f0 <states.1712>
    800026ee:	a00d                	j	80002710 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026f0:	ee06a583          	lw	a1,-288(a3)
    800026f4:	8556                	mv	a0,s5
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	e9c080e7          	jalr	-356(ra) # 80000592 <printf>
    printf("\n");
    800026fe:	8552                	mv	a0,s4
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	e92080e7          	jalr	-366(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002708:	16848493          	addi	s1,s1,360
    8000270c:	03248163          	beq	s1,s2,8000272e <procdump+0x98>
    if(p->state == UNUSED)
    80002710:	86a6                	mv	a3,s1
    80002712:	ec04a783          	lw	a5,-320(s1)
    80002716:	dbed                	beqz	a5,80002708 <procdump+0x72>
      state = "???";
    80002718:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271a:	fcfb6be3          	bltu	s6,a5,800026f0 <procdump+0x5a>
    8000271e:	1782                	slli	a5,a5,0x20
    80002720:	9381                	srli	a5,a5,0x20
    80002722:	078e                	slli	a5,a5,0x3
    80002724:	97de                	add	a5,a5,s7
    80002726:	6390                	ld	a2,0(a5)
    80002728:	f661                	bnez	a2,800026f0 <procdump+0x5a>
      state = "???";
    8000272a:	864e                	mv	a2,s3
    8000272c:	b7d1                	j	800026f0 <procdump+0x5a>
  }
}
    8000272e:	60a6                	ld	ra,72(sp)
    80002730:	6406                	ld	s0,64(sp)
    80002732:	74e2                	ld	s1,56(sp)
    80002734:	7942                	ld	s2,48(sp)
    80002736:	79a2                	ld	s3,40(sp)
    80002738:	7a02                	ld	s4,32(sp)
    8000273a:	6ae2                	ld	s5,24(sp)
    8000273c:	6b42                	ld	s6,16(sp)
    8000273e:	6ba2                	ld	s7,8(sp)
    80002740:	6161                	addi	sp,sp,80
    80002742:	8082                	ret

0000000080002744 <swtch>:
    80002744:	00153023          	sd	ra,0(a0)
    80002748:	00253423          	sd	sp,8(a0)
    8000274c:	e900                	sd	s0,16(a0)
    8000274e:	ed04                	sd	s1,24(a0)
    80002750:	03253023          	sd	s2,32(a0)
    80002754:	03353423          	sd	s3,40(a0)
    80002758:	03453823          	sd	s4,48(a0)
    8000275c:	03553c23          	sd	s5,56(a0)
    80002760:	05653023          	sd	s6,64(a0)
    80002764:	05753423          	sd	s7,72(a0)
    80002768:	05853823          	sd	s8,80(a0)
    8000276c:	05953c23          	sd	s9,88(a0)
    80002770:	07a53023          	sd	s10,96(a0)
    80002774:	07b53423          	sd	s11,104(a0)
    80002778:	0005b083          	ld	ra,0(a1)
    8000277c:	0085b103          	ld	sp,8(a1)
    80002780:	6980                	ld	s0,16(a1)
    80002782:	6d84                	ld	s1,24(a1)
    80002784:	0205b903          	ld	s2,32(a1)
    80002788:	0285b983          	ld	s3,40(a1)
    8000278c:	0305ba03          	ld	s4,48(a1)
    80002790:	0385ba83          	ld	s5,56(a1)
    80002794:	0405bb03          	ld	s6,64(a1)
    80002798:	0485bb83          	ld	s7,72(a1)
    8000279c:	0505bc03          	ld	s8,80(a1)
    800027a0:	0585bc83          	ld	s9,88(a1)
    800027a4:	0605bd03          	ld	s10,96(a1)
    800027a8:	0685bd83          	ld	s11,104(a1)
    800027ac:	8082                	ret

00000000800027ae <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027ae:	1141                	addi	sp,sp,-16
    800027b0:	e406                	sd	ra,8(sp)
    800027b2:	e022                	sd	s0,0(sp)
    800027b4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027b6:	00006597          	auipc	a1,0x6
    800027ba:	b6258593          	addi	a1,a1,-1182 # 80008318 <states.1712+0x28>
    800027be:	00235517          	auipc	a0,0x235
    800027c2:	faa50513          	addi	a0,a0,-86 # 80237768 <tickslock>
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	504080e7          	jalr	1284(ra) # 80000cca <initlock>
}
    800027ce:	60a2                	ld	ra,8(sp)
    800027d0:	6402                	ld	s0,0(sp)
    800027d2:	0141                	addi	sp,sp,16
    800027d4:	8082                	ret

00000000800027d6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027d6:	1141                	addi	sp,sp,-16
    800027d8:	e422                	sd	s0,8(sp)
    800027da:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027dc:	00003797          	auipc	a5,0x3
    800027e0:	58478793          	addi	a5,a5,1412 # 80005d60 <kernelvec>
    800027e4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027e8:	6422                	ld	s0,8(sp)
    800027ea:	0141                	addi	sp,sp,16
    800027ec:	8082                	ret

00000000800027ee <cowfault>:

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
int cowfault(pagetable_t pagetable,uint64 va){
    800027ee:	7179                	addi	sp,sp,-48
    800027f0:	f406                	sd	ra,40(sp)
    800027f2:	f022                	sd	s0,32(sp)
    800027f4:	ec26                	sd	s1,24(sp)
    800027f6:	e84a                	sd	s2,16(sp)
    800027f8:	e44e                	sd	s3,8(sp)
    800027fa:	1800                	addi	s0,sp,48
    800027fc:	84ae                	mv	s1,a1
  pte_t* pte= walk(pagetable,va,0);
    800027fe:	4601                	li	a2,0
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	942080e7          	jalr	-1726(ra) # 80001142 <walk>
  if(va>MAXVA)
    80002808:	4785                	li	a5,1
    8000280a:	179a                	slli	a5,a5,0x26
    8000280c:	0697e963          	bltu	a5,s1,8000287e <cowfault+0x90>
    80002810:	892a                	mv	s2,a0
    return -1;
  if(pte==0||(*pte&PTE_U)==0||(*pte&PTE_V)==0||(*pte&PTE_RSW)==0)
    80002812:	c925                	beqz	a0,80002882 <cowfault+0x94>
    80002814:	611c                	ld	a5,0(a0)
    80002816:	1117f793          	andi	a5,a5,273
    8000281a:	11100713          	li	a4,273
    8000281e:	06e79463          	bne	a5,a4,80002886 <cowfault+0x98>
    return -1;
  uint64 pa2 =(uint64)kalloc();
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	406080e7          	jalr	1030(ra) # 80000c28 <kalloc>
    8000282a:	84aa                	mv	s1,a0
  if(pa2==0){
    8000282c:	cd1d                	beqz	a0,8000286a <cowfault+0x7c>
    printf("cow kalloc failed\n");
    return -1;
  }
  uint64 pa1 = PTE2PA(*pte);
    8000282e:	00093983          	ld	s3,0(s2)
    80002832:	00a9d993          	srli	s3,s3,0xa
    80002836:	09b2                	slli	s3,s3,0xc
  memmove((void*)pa2, (void*)pa1, PGSIZE);
    80002838:	6605                	lui	a2,0x1
    8000283a:	85ce                	mv	a1,s3
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	67a080e7          	jalr	1658(ra) # 80000eb6 <memmove>
  *pte=PA2PTE(pa2)|PTE_R|PTE_W|PTE_X|PTE_V|PTE_U;
    80002844:	80b1                	srli	s1,s1,0xc
    80002846:	04aa                	slli	s1,s1,0xa
    80002848:	01f4e493          	ori	s1,s1,31
    8000284c:	00993023          	sd	s1,0(s2)
  kfree((void*)pa1);
    80002850:	854e                	mv	a0,s3
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	24e080e7          	jalr	590(ra) # 80000aa0 <kfree>
  return 0;
    8000285a:	4501                	li	a0,0
}
    8000285c:	70a2                	ld	ra,40(sp)
    8000285e:	7402                	ld	s0,32(sp)
    80002860:	64e2                	ld	s1,24(sp)
    80002862:	6942                	ld	s2,16(sp)
    80002864:	69a2                	ld	s3,8(sp)
    80002866:	6145                	addi	sp,sp,48
    80002868:	8082                	ret
    printf("cow kalloc failed\n");
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	ab650513          	addi	a0,a0,-1354 # 80008320 <states.1712+0x30>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d20080e7          	jalr	-736(ra) # 80000592 <printf>
    return -1;
    8000287a:	557d                	li	a0,-1
    8000287c:	b7c5                	j	8000285c <cowfault+0x6e>
    return -1;
    8000287e:	557d                	li	a0,-1
    80002880:	bff1                	j	8000285c <cowfault+0x6e>
    return -1;
    80002882:	557d                	li	a0,-1
    80002884:	bfe1                	j	8000285c <cowfault+0x6e>
    80002886:	557d                	li	a0,-1
    80002888:	bfd1                	j	8000285c <cowfault+0x6e>

000000008000288a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000288a:	1141                	addi	sp,sp,-16
    8000288c:	e406                	sd	ra,8(sp)
    8000288e:	e022                	sd	s0,0(sp)
    80002890:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	2e6080e7          	jalr	742(ra) # 80001b78 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000289e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028a4:	00004617          	auipc	a2,0x4
    800028a8:	75c60613          	addi	a2,a2,1884 # 80007000 <_trampoline>
    800028ac:	00004697          	auipc	a3,0x4
    800028b0:	75468693          	addi	a3,a3,1876 # 80007000 <_trampoline>
    800028b4:	8e91                	sub	a3,a3,a2
    800028b6:	040007b7          	lui	a5,0x4000
    800028ba:	17fd                	addi	a5,a5,-1
    800028bc:	07b2                	slli	a5,a5,0xc
    800028be:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028c4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028c6:	180026f3          	csrr	a3,satp
    800028ca:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028cc:	6d38                	ld	a4,88(a0)
    800028ce:	6134                	ld	a3,64(a0)
    800028d0:	6585                	lui	a1,0x1
    800028d2:	96ae                	add	a3,a3,a1
    800028d4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028d6:	6d38                	ld	a4,88(a0)
    800028d8:	00000697          	auipc	a3,0x0
    800028dc:	13868693          	addi	a3,a3,312 # 80002a10 <usertrap>
    800028e0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028e2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028e4:	8692                	mv	a3,tp
    800028e6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028ec:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028f0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028fa:	6f18                	ld	a4,24(a4)
    800028fc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002900:	692c                	ld	a1,80(a0)
    80002902:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002904:	00004717          	auipc	a4,0x4
    80002908:	78c70713          	addi	a4,a4,1932 # 80007090 <userret>
    8000290c:	8f11                	sub	a4,a4,a2
    8000290e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002910:	577d                	li	a4,-1
    80002912:	177e                	slli	a4,a4,0x3f
    80002914:	8dd9                	or	a1,a1,a4
    80002916:	02000537          	lui	a0,0x2000
    8000291a:	157d                	addi	a0,a0,-1
    8000291c:	0536                	slli	a0,a0,0xd
    8000291e:	9782                	jalr	a5
}
    80002920:	60a2                	ld	ra,8(sp)
    80002922:	6402                	ld	s0,0(sp)
    80002924:	0141                	addi	sp,sp,16
    80002926:	8082                	ret

0000000080002928 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002928:	1101                	addi	sp,sp,-32
    8000292a:	ec06                	sd	ra,24(sp)
    8000292c:	e822                	sd	s0,16(sp)
    8000292e:	e426                	sd	s1,8(sp)
    80002930:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002932:	00235497          	auipc	s1,0x235
    80002936:	e3648493          	addi	s1,s1,-458 # 80237768 <tickslock>
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	41e080e7          	jalr	1054(ra) # 80000d5a <acquire>
  ticks++;
    80002944:	00006517          	auipc	a0,0x6
    80002948:	6dc50513          	addi	a0,a0,1756 # 80009020 <ticks>
    8000294c:	411c                	lw	a5,0(a0)
    8000294e:	2785                	addiw	a5,a5,1
    80002950:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002952:	00000097          	auipc	ra,0x0
    80002956:	bbc080e7          	jalr	-1092(ra) # 8000250e <wakeup>
  release(&tickslock);
    8000295a:	8526                	mv	a0,s1
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	4b2080e7          	jalr	1202(ra) # 80000e0e <release>
}
    80002964:	60e2                	ld	ra,24(sp)
    80002966:	6442                	ld	s0,16(sp)
    80002968:	64a2                	ld	s1,8(sp)
    8000296a:	6105                	addi	sp,sp,32
    8000296c:	8082                	ret

000000008000296e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002978:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000297c:	00074d63          	bltz	a4,80002996 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002980:	57fd                	li	a5,-1
    80002982:	17fe                	slli	a5,a5,0x3f
    80002984:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002986:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002988:	06f70363          	beq	a4,a5,800029ee <devintr+0x80>
  }
}
    8000298c:	60e2                	ld	ra,24(sp)
    8000298e:	6442                	ld	s0,16(sp)
    80002990:	64a2                	ld	s1,8(sp)
    80002992:	6105                	addi	sp,sp,32
    80002994:	8082                	ret
     (scause & 0xff) == 9){
    80002996:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000299a:	46a5                	li	a3,9
    8000299c:	fed792e3          	bne	a5,a3,80002980 <devintr+0x12>
    int irq = plic_claim();
    800029a0:	00003097          	auipc	ra,0x3
    800029a4:	4c8080e7          	jalr	1224(ra) # 80005e68 <plic_claim>
    800029a8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029aa:	47a9                	li	a5,10
    800029ac:	02f50763          	beq	a0,a5,800029da <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029b0:	4785                	li	a5,1
    800029b2:	02f50963          	beq	a0,a5,800029e4 <devintr+0x76>
    return 1;
    800029b6:	4505                	li	a0,1
    } else if(irq){
    800029b8:	d8f1                	beqz	s1,8000298c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029ba:	85a6                	mv	a1,s1
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	97c50513          	addi	a0,a0,-1668 # 80008338 <states.1712+0x48>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bce080e7          	jalr	-1074(ra) # 80000592 <printf>
      plic_complete(irq);
    800029cc:	8526                	mv	a0,s1
    800029ce:	00003097          	auipc	ra,0x3
    800029d2:	4be080e7          	jalr	1214(ra) # 80005e8c <plic_complete>
    return 1;
    800029d6:	4505                	li	a0,1
    800029d8:	bf55                	j	8000298c <devintr+0x1e>
      uartintr();
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	ffa080e7          	jalr	-6(ra) # 800009d4 <uartintr>
    800029e2:	b7ed                	j	800029cc <devintr+0x5e>
      virtio_disk_intr();
    800029e4:	00004097          	auipc	ra,0x4
    800029e8:	942080e7          	jalr	-1726(ra) # 80006326 <virtio_disk_intr>
    800029ec:	b7c5                	j	800029cc <devintr+0x5e>
    if(cpuid() == 0){
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	15e080e7          	jalr	350(ra) # 80001b4c <cpuid>
    800029f6:	c901                	beqz	a0,80002a06 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029f8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029fe:	14479073          	csrw	sip,a5
    return 2;
    80002a02:	4509                	li	a0,2
    80002a04:	b761                	j	8000298c <devintr+0x1e>
      clockintr();
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	f22080e7          	jalr	-222(ra) # 80002928 <clockintr>
    80002a0e:	b7ed                	j	800029f8 <devintr+0x8a>

0000000080002a10 <usertrap>:
{
    80002a10:	1101                	addi	sp,sp,-32
    80002a12:	ec06                	sd	ra,24(sp)
    80002a14:	e822                	sd	s0,16(sp)
    80002a16:	e426                	sd	s1,8(sp)
    80002a18:	e04a                	sd	s2,0(sp)
    80002a1a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a20:	1007f793          	andi	a5,a5,256
    80002a24:	e3b9                	bnez	a5,80002a6a <usertrap+0x5a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a26:	00003797          	auipc	a5,0x3
    80002a2a:	33a78793          	addi	a5,a5,826 # 80005d60 <kernelvec>
    80002a2e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	146080e7          	jalr	326(ra) # 80001b78 <myproc>
    80002a3a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a3c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3e:	14102773          	csrr	a4,sepc
    80002a42:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a44:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a48:	47a1                	li	a5,8
    80002a4a:	02f70863          	beq	a4,a5,80002a7a <usertrap+0x6a>
    80002a4e:	14202773          	csrr	a4,scause
  }else if(r_scause() == 0xf) {
    80002a52:	47bd                	li	a5,15
    80002a54:	06f70563          	beq	a4,a5,80002abe <usertrap+0xae>
  else if((which_dev = devintr()) != 0){
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	f16080e7          	jalr	-234(ra) # 8000296e <devintr>
    80002a60:	892a                	mv	s2,a0
    80002a62:	c935                	beqz	a0,80002ad6 <usertrap+0xc6>
  if(p->killed)
    80002a64:	589c                	lw	a5,48(s1)
    80002a66:	c7dd                	beqz	a5,80002b14 <usertrap+0x104>
    80002a68:	a04d                	j	80002b0a <usertrap+0xfa>
    panic("usertrap: not from user mode");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	8ee50513          	addi	a0,a0,-1810 # 80008358 <states.1712+0x68>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ad6080e7          	jalr	-1322(ra) # 80000548 <panic>
    if(p->killed)
    80002a7a:	591c                	lw	a5,48(a0)
    80002a7c:	eb9d                	bnez	a5,80002ab2 <usertrap+0xa2>
    p->trapframe->epc += 4;
    80002a7e:	6cb8                	ld	a4,88(s1)
    80002a80:	6f1c                	ld	a5,24(a4)
    80002a82:	0791                	addi	a5,a5,4
    80002a84:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8e:	10079073          	csrw	sstatus,a5
    syscall();
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	2d8080e7          	jalr	728(ra) # 80002d6a <syscall>
  if(p->killed)
    80002a9a:	589c                	lw	a5,48(s1)
    80002a9c:	e7c1                	bnez	a5,80002b24 <usertrap+0x114>
  usertrapret();
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	dec080e7          	jalr	-532(ra) # 8000288a <usertrapret>
}
    80002aa6:	60e2                	ld	ra,24(sp)
    80002aa8:	6442                	ld	s0,16(sp)
    80002aaa:	64a2                	ld	s1,8(sp)
    80002aac:	6902                	ld	s2,0(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
      exit(-1);
    80002ab2:	557d                	li	a0,-1
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	78e080e7          	jalr	1934(ra) # 80002242 <exit>
    80002abc:	b7c9                	j	80002a7e <usertrap+0x6e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002abe:	143025f3          	csrr	a1,stval
  if(cowfault(p->pagetable,r_stval())<0)
    80002ac2:	6928                	ld	a0,80(a0)
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	d2a080e7          	jalr	-726(ra) # 800027ee <cowfault>
    80002acc:	fc0557e3          	bgez	a0,80002a9a <usertrap+0x8a>
      p->killed=1;
    80002ad0:	4785                	li	a5,1
    80002ad2:	d89c                	sw	a5,48(s1)
    80002ad4:	a815                	j	80002b08 <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ada:	5c90                	lw	a2,56(s1)
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	89c50513          	addi	a0,a0,-1892 # 80008378 <states.1712+0x88>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	aae080e7          	jalr	-1362(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002af0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	8b450513          	addi	a0,a0,-1868 # 800083a8 <states.1712+0xb8>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a96080e7          	jalr	-1386(ra) # 80000592 <printf>
    p->killed = 1;
    80002b04:	4785                	li	a5,1
    80002b06:	d89c                	sw	a5,48(s1)
{
    80002b08:	4901                	li	s2,0
    exit(-1);
    80002b0a:	557d                	li	a0,-1
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	736080e7          	jalr	1846(ra) # 80002242 <exit>
  if(which_dev == 2)
    80002b14:	4789                	li	a5,2
    80002b16:	f8f914e3          	bne	s2,a5,80002a9e <usertrap+0x8e>
    yield();
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	832080e7          	jalr	-1998(ra) # 8000234c <yield>
    80002b22:	bfb5                	j	80002a9e <usertrap+0x8e>
  if(p->killed)
    80002b24:	4901                	li	s2,0
    80002b26:	b7d5                	j	80002b0a <usertrap+0xfa>

0000000080002b28 <kerneltrap>:
{
    80002b28:	7179                	addi	sp,sp,-48
    80002b2a:	f406                	sd	ra,40(sp)
    80002b2c:	f022                	sd	s0,32(sp)
    80002b2e:	ec26                	sd	s1,24(sp)
    80002b30:	e84a                	sd	s2,16(sp)
    80002b32:	e44e                	sd	s3,8(sp)
    80002b34:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b36:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b42:	1004f793          	andi	a5,s1,256
    80002b46:	cb85                	beqz	a5,80002b76 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b4c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b4e:	ef85                	bnez	a5,80002b86 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	e1e080e7          	jalr	-482(ra) # 8000296e <devintr>
    80002b58:	cd1d                	beqz	a0,80002b96 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b5a:	4789                	li	a5,2
    80002b5c:	06f50a63          	beq	a0,a5,80002bd0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b60:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b64:	10049073          	csrw	sstatus,s1
}
    80002b68:	70a2                	ld	ra,40(sp)
    80002b6a:	7402                	ld	s0,32(sp)
    80002b6c:	64e2                	ld	s1,24(sp)
    80002b6e:	6942                	ld	s2,16(sp)
    80002b70:	69a2                	ld	s3,8(sp)
    80002b72:	6145                	addi	sp,sp,48
    80002b74:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	85250513          	addi	a0,a0,-1966 # 800083c8 <states.1712+0xd8>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	9ca080e7          	jalr	-1590(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	86a50513          	addi	a0,a0,-1942 # 800083f0 <states.1712+0x100>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	9ba080e7          	jalr	-1606(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002b96:	85ce                	mv	a1,s3
    80002b98:	00006517          	auipc	a0,0x6
    80002b9c:	87850513          	addi	a0,a0,-1928 # 80008410 <states.1712+0x120>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9f2080e7          	jalr	-1550(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bac:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	87050513          	addi	a0,a0,-1936 # 80008420 <states.1712+0x130>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9da080e7          	jalr	-1574(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	87850513          	addi	a0,a0,-1928 # 80008438 <states.1712+0x148>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	980080e7          	jalr	-1664(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	fa8080e7          	jalr	-88(ra) # 80001b78 <myproc>
    80002bd8:	d541                	beqz	a0,80002b60 <kerneltrap+0x38>
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	f9e080e7          	jalr	-98(ra) # 80001b78 <myproc>
    80002be2:	4d18                	lw	a4,24(a0)
    80002be4:	478d                	li	a5,3
    80002be6:	f6f71de3          	bne	a4,a5,80002b60 <kerneltrap+0x38>
    yield();
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	762080e7          	jalr	1890(ra) # 8000234c <yield>
    80002bf2:	b7bd                	j	80002b60 <kerneltrap+0x38>

0000000080002bf4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	1000                	addi	s0,sp,32
    80002bfe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	f78080e7          	jalr	-136(ra) # 80001b78 <myproc>
  switch (n) {
    80002c08:	4795                	li	a5,5
    80002c0a:	0497e163          	bltu	a5,s1,80002c4c <argraw+0x58>
    80002c0e:	048a                	slli	s1,s1,0x2
    80002c10:	00006717          	auipc	a4,0x6
    80002c14:	86070713          	addi	a4,a4,-1952 # 80008470 <states.1712+0x180>
    80002c18:	94ba                	add	s1,s1,a4
    80002c1a:	409c                	lw	a5,0(s1)
    80002c1c:	97ba                	add	a5,a5,a4
    80002c1e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c20:	6d3c                	ld	a5,88(a0)
    80002c22:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret
    return p->trapframe->a1;
    80002c2e:	6d3c                	ld	a5,88(a0)
    80002c30:	7fa8                	ld	a0,120(a5)
    80002c32:	bfcd                	j	80002c24 <argraw+0x30>
    return p->trapframe->a2;
    80002c34:	6d3c                	ld	a5,88(a0)
    80002c36:	63c8                	ld	a0,128(a5)
    80002c38:	b7f5                	j	80002c24 <argraw+0x30>
    return p->trapframe->a3;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	67c8                	ld	a0,136(a5)
    80002c3e:	b7dd                	j	80002c24 <argraw+0x30>
    return p->trapframe->a4;
    80002c40:	6d3c                	ld	a5,88(a0)
    80002c42:	6bc8                	ld	a0,144(a5)
    80002c44:	b7c5                	j	80002c24 <argraw+0x30>
    return p->trapframe->a5;
    80002c46:	6d3c                	ld	a5,88(a0)
    80002c48:	6fc8                	ld	a0,152(a5)
    80002c4a:	bfe9                	j	80002c24 <argraw+0x30>
  panic("argraw");
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	7fc50513          	addi	a0,a0,2044 # 80008448 <states.1712+0x158>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	8f4080e7          	jalr	-1804(ra) # 80000548 <panic>

0000000080002c5c <fetchaddr>:
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	e04a                	sd	s2,0(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84aa                	mv	s1,a0
    80002c6a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	f0c080e7          	jalr	-244(ra) # 80001b78 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c74:	653c                	ld	a5,72(a0)
    80002c76:	02f4f863          	bgeu	s1,a5,80002ca6 <fetchaddr+0x4a>
    80002c7a:	00848713          	addi	a4,s1,8
    80002c7e:	02e7e663          	bltu	a5,a4,80002caa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c82:	46a1                	li	a3,8
    80002c84:	8626                	mv	a2,s1
    80002c86:	85ca                	mv	a1,s2
    80002c88:	6928                	ld	a0,80(a0)
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	c6e080e7          	jalr	-914(ra) # 800018f8 <copyin>
    80002c92:	00a03533          	snez	a0,a0
    80002c96:	40a00533          	neg	a0,a0
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6902                	ld	s2,0(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret
    return -1;
    80002ca6:	557d                	li	a0,-1
    80002ca8:	bfcd                	j	80002c9a <fetchaddr+0x3e>
    80002caa:	557d                	li	a0,-1
    80002cac:	b7fd                	j	80002c9a <fetchaddr+0x3e>

0000000080002cae <fetchstr>:
{
    80002cae:	7179                	addi	sp,sp,-48
    80002cb0:	f406                	sd	ra,40(sp)
    80002cb2:	f022                	sd	s0,32(sp)
    80002cb4:	ec26                	sd	s1,24(sp)
    80002cb6:	e84a                	sd	s2,16(sp)
    80002cb8:	e44e                	sd	s3,8(sp)
    80002cba:	1800                	addi	s0,sp,48
    80002cbc:	892a                	mv	s2,a0
    80002cbe:	84ae                	mv	s1,a1
    80002cc0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	eb6080e7          	jalr	-330(ra) # 80001b78 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cca:	86ce                	mv	a3,s3
    80002ccc:	864a                	mv	a2,s2
    80002cce:	85a6                	mv	a1,s1
    80002cd0:	6928                	ld	a0,80(a0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	cb2080e7          	jalr	-846(ra) # 80001984 <copyinstr>
  if(err < 0)
    80002cda:	00054763          	bltz	a0,80002ce8 <fetchstr+0x3a>
  return strlen(buf);
    80002cde:	8526                	mv	a0,s1
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	2fe080e7          	jalr	766(ra) # 80000fde <strlen>
}
    80002ce8:	70a2                	ld	ra,40(sp)
    80002cea:	7402                	ld	s0,32(sp)
    80002cec:	64e2                	ld	s1,24(sp)
    80002cee:	6942                	ld	s2,16(sp)
    80002cf0:	69a2                	ld	s3,8(sp)
    80002cf2:	6145                	addi	sp,sp,48
    80002cf4:	8082                	ret

0000000080002cf6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	1000                	addi	s0,sp,32
    80002d00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	ef2080e7          	jalr	-270(ra) # 80002bf4 <argraw>
    80002d0a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d0c:	4501                	li	a0,0
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	64a2                	ld	s1,8(sp)
    80002d14:	6105                	addi	sp,sp,32
    80002d16:	8082                	ret

0000000080002d18 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
    80002d22:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	ed0080e7          	jalr	-304(ra) # 80002bf4 <argraw>
    80002d2c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d2e:	4501                	li	a0,0
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6105                	addi	sp,sp,32
    80002d38:	8082                	ret

0000000080002d3a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	e426                	sd	s1,8(sp)
    80002d42:	e04a                	sd	s2,0(sp)
    80002d44:	1000                	addi	s0,sp,32
    80002d46:	84ae                	mv	s1,a1
    80002d48:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	eaa080e7          	jalr	-342(ra) # 80002bf4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d52:	864a                	mv	a2,s2
    80002d54:	85a6                	mv	a1,s1
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	f58080e7          	jalr	-168(ra) # 80002cae <fetchstr>
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	64a2                	ld	s1,8(sp)
    80002d64:	6902                	ld	s2,0(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	e04a                	sd	s2,0(sp)
    80002d74:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	e02080e7          	jalr	-510(ra) # 80001b78 <myproc>
    80002d7e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d80:	05853903          	ld	s2,88(a0)
    80002d84:	0a893783          	ld	a5,168(s2)
    80002d88:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d8c:	37fd                	addiw	a5,a5,-1
    80002d8e:	4751                	li	a4,20
    80002d90:	00f76f63          	bltu	a4,a5,80002dae <syscall+0x44>
    80002d94:	00369713          	slli	a4,a3,0x3
    80002d98:	00005797          	auipc	a5,0x5
    80002d9c:	6f078793          	addi	a5,a5,1776 # 80008488 <syscalls>
    80002da0:	97ba                	add	a5,a5,a4
    80002da2:	639c                	ld	a5,0(a5)
    80002da4:	c789                	beqz	a5,80002dae <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002da6:	9782                	jalr	a5
    80002da8:	06a93823          	sd	a0,112(s2)
    80002dac:	a839                	j	80002dca <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dae:	15848613          	addi	a2,s1,344
    80002db2:	5c8c                	lw	a1,56(s1)
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	69c50513          	addi	a0,a0,1692 # 80008450 <states.1712+0x160>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7d6080e7          	jalr	2006(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dc4:	6cbc                	ld	a5,88(s1)
    80002dc6:	577d                	li	a4,-1
    80002dc8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6902                	ld	s2,0(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dde:	fec40593          	addi	a1,s0,-20
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	f12080e7          	jalr	-238(ra) # 80002cf6 <argint>
    return -1;
    80002dec:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dee:	00054963          	bltz	a0,80002e00 <sys_exit+0x2a>
  exit(n);
    80002df2:	fec42503          	lw	a0,-20(s0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	44c080e7          	jalr	1100(ra) # 80002242 <exit>
  return 0;  // not reached
    80002dfe:	4781                	li	a5,0
}
    80002e00:	853e                	mv	a0,a5
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e0a:	1141                	addi	sp,sp,-16
    80002e0c:	e406                	sd	ra,8(sp)
    80002e0e:	e022                	sd	s0,0(sp)
    80002e10:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	d66080e7          	jalr	-666(ra) # 80001b78 <myproc>
}
    80002e1a:	5d08                	lw	a0,56(a0)
    80002e1c:	60a2                	ld	ra,8(sp)
    80002e1e:	6402                	ld	s0,0(sp)
    80002e20:	0141                	addi	sp,sp,16
    80002e22:	8082                	ret

0000000080002e24 <sys_fork>:

uint64
sys_fork(void)
{
    80002e24:	1141                	addi	sp,sp,-16
    80002e26:	e406                	sd	ra,8(sp)
    80002e28:	e022                	sd	s0,0(sp)
    80002e2a:	0800                	addi	s0,sp,16
  return fork();
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	10c080e7          	jalr	268(ra) # 80001f38 <fork>
}
    80002e34:	60a2                	ld	ra,8(sp)
    80002e36:	6402                	ld	s0,0(sp)
    80002e38:	0141                	addi	sp,sp,16
    80002e3a:	8082                	ret

0000000080002e3c <sys_wait>:

uint64
sys_wait(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e44:	fe840593          	addi	a1,s0,-24
    80002e48:	4501                	li	a0,0
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	ece080e7          	jalr	-306(ra) # 80002d18 <argaddr>
    80002e52:	87aa                	mv	a5,a0
    return -1;
    80002e54:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e56:	0007c863          	bltz	a5,80002e66 <sys_wait+0x2a>
  return wait(p);
    80002e5a:	fe843503          	ld	a0,-24(s0)
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	5a8080e7          	jalr	1448(ra) # 80002406 <wait>
}
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e6e:	7179                	addi	sp,sp,-48
    80002e70:	f406                	sd	ra,40(sp)
    80002e72:	f022                	sd	s0,32(sp)
    80002e74:	ec26                	sd	s1,24(sp)
    80002e76:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e78:	fdc40593          	addi	a1,s0,-36
    80002e7c:	4501                	li	a0,0
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	e78080e7          	jalr	-392(ra) # 80002cf6 <argint>
    80002e86:	87aa                	mv	a5,a0
    return -1;
    80002e88:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e8a:	0207c063          	bltz	a5,80002eaa <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	cea080e7          	jalr	-790(ra) # 80001b78 <myproc>
    80002e96:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e98:	fdc42503          	lw	a0,-36(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	028080e7          	jalr	40(ra) # 80001ec4 <growproc>
    80002ea4:	00054863          	bltz	a0,80002eb4 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ea8:	8526                	mv	a0,s1
}
    80002eaa:	70a2                	ld	ra,40(sp)
    80002eac:	7402                	ld	s0,32(sp)
    80002eae:	64e2                	ld	s1,24(sp)
    80002eb0:	6145                	addi	sp,sp,48
    80002eb2:	8082                	ret
    return -1;
    80002eb4:	557d                	li	a0,-1
    80002eb6:	bfd5                	j	80002eaa <sys_sbrk+0x3c>

0000000080002eb8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eb8:	7139                	addi	sp,sp,-64
    80002eba:	fc06                	sd	ra,56(sp)
    80002ebc:	f822                	sd	s0,48(sp)
    80002ebe:	f426                	sd	s1,40(sp)
    80002ec0:	f04a                	sd	s2,32(sp)
    80002ec2:	ec4e                	sd	s3,24(sp)
    80002ec4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ec6:	fcc40593          	addi	a1,s0,-52
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	e2a080e7          	jalr	-470(ra) # 80002cf6 <argint>
    return -1;
    80002ed4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ed6:	06054563          	bltz	a0,80002f40 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eda:	00235517          	auipc	a0,0x235
    80002ede:	88e50513          	addi	a0,a0,-1906 # 80237768 <tickslock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	e78080e7          	jalr	-392(ra) # 80000d5a <acquire>
  ticks0 = ticks;
    80002eea:	00006917          	auipc	s2,0x6
    80002eee:	13692903          	lw	s2,310(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ef2:	fcc42783          	lw	a5,-52(s0)
    80002ef6:	cf85                	beqz	a5,80002f2e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ef8:	00235997          	auipc	s3,0x235
    80002efc:	87098993          	addi	s3,s3,-1936 # 80237768 <tickslock>
    80002f00:	00006497          	auipc	s1,0x6
    80002f04:	12048493          	addi	s1,s1,288 # 80009020 <ticks>
    if(myproc()->killed){
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	c70080e7          	jalr	-912(ra) # 80001b78 <myproc>
    80002f10:	591c                	lw	a5,48(a0)
    80002f12:	ef9d                	bnez	a5,80002f50 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f14:	85ce                	mv	a1,s3
    80002f16:	8526                	mv	a0,s1
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	470080e7          	jalr	1136(ra) # 80002388 <sleep>
  while(ticks - ticks0 < n){
    80002f20:	409c                	lw	a5,0(s1)
    80002f22:	412787bb          	subw	a5,a5,s2
    80002f26:	fcc42703          	lw	a4,-52(s0)
    80002f2a:	fce7efe3          	bltu	a5,a4,80002f08 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f2e:	00235517          	auipc	a0,0x235
    80002f32:	83a50513          	addi	a0,a0,-1990 # 80237768 <tickslock>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	ed8080e7          	jalr	-296(ra) # 80000e0e <release>
  return 0;
    80002f3e:	4781                	li	a5,0
}
    80002f40:	853e                	mv	a0,a5
    80002f42:	70e2                	ld	ra,56(sp)
    80002f44:	7442                	ld	s0,48(sp)
    80002f46:	74a2                	ld	s1,40(sp)
    80002f48:	7902                	ld	s2,32(sp)
    80002f4a:	69e2                	ld	s3,24(sp)
    80002f4c:	6121                	addi	sp,sp,64
    80002f4e:	8082                	ret
      release(&tickslock);
    80002f50:	00235517          	auipc	a0,0x235
    80002f54:	81850513          	addi	a0,a0,-2024 # 80237768 <tickslock>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	eb6080e7          	jalr	-330(ra) # 80000e0e <release>
      return -1;
    80002f60:	57fd                	li	a5,-1
    80002f62:	bff9                	j	80002f40 <sys_sleep+0x88>

0000000080002f64 <sys_kill>:

uint64
sys_kill(void)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f6c:	fec40593          	addi	a1,s0,-20
    80002f70:	4501                	li	a0,0
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	d84080e7          	jalr	-636(ra) # 80002cf6 <argint>
    80002f7a:	87aa                	mv	a5,a0
    return -1;
    80002f7c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f7e:	0007c863          	bltz	a5,80002f8e <sys_kill+0x2a>
  return kill(pid);
    80002f82:	fec42503          	lw	a0,-20(s0)
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	5f2080e7          	jalr	1522(ra) # 80002578 <kill>
}
    80002f8e:	60e2                	ld	ra,24(sp)
    80002f90:	6442                	ld	s0,16(sp)
    80002f92:	6105                	addi	sp,sp,32
    80002f94:	8082                	ret

0000000080002f96 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f96:	1101                	addi	sp,sp,-32
    80002f98:	ec06                	sd	ra,24(sp)
    80002f9a:	e822                	sd	s0,16(sp)
    80002f9c:	e426                	sd	s1,8(sp)
    80002f9e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fa0:	00234517          	auipc	a0,0x234
    80002fa4:	7c850513          	addi	a0,a0,1992 # 80237768 <tickslock>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	db2080e7          	jalr	-590(ra) # 80000d5a <acquire>
  xticks = ticks;
    80002fb0:	00006497          	auipc	s1,0x6
    80002fb4:	0704a483          	lw	s1,112(s1) # 80009020 <ticks>
  release(&tickslock);
    80002fb8:	00234517          	auipc	a0,0x234
    80002fbc:	7b050513          	addi	a0,a0,1968 # 80237768 <tickslock>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	e4e080e7          	jalr	-434(ra) # 80000e0e <release>
  return xticks;
}
    80002fc8:	02049513          	slli	a0,s1,0x20
    80002fcc:	9101                	srli	a0,a0,0x20
    80002fce:	60e2                	ld	ra,24(sp)
    80002fd0:	6442                	ld	s0,16(sp)
    80002fd2:	64a2                	ld	s1,8(sp)
    80002fd4:	6105                	addi	sp,sp,32
    80002fd6:	8082                	ret

0000000080002fd8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fd8:	7179                	addi	sp,sp,-48
    80002fda:	f406                	sd	ra,40(sp)
    80002fdc:	f022                	sd	s0,32(sp)
    80002fde:	ec26                	sd	s1,24(sp)
    80002fe0:	e84a                	sd	s2,16(sp)
    80002fe2:	e44e                	sd	s3,8(sp)
    80002fe4:	e052                	sd	s4,0(sp)
    80002fe6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fe8:	00005597          	auipc	a1,0x5
    80002fec:	55058593          	addi	a1,a1,1360 # 80008538 <syscalls+0xb0>
    80002ff0:	00234517          	auipc	a0,0x234
    80002ff4:	79050513          	addi	a0,a0,1936 # 80237780 <bcache>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	cd2080e7          	jalr	-814(ra) # 80000cca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003000:	0023c797          	auipc	a5,0x23c
    80003004:	78078793          	addi	a5,a5,1920 # 8023f780 <bcache+0x8000>
    80003008:	0023d717          	auipc	a4,0x23d
    8000300c:	9e070713          	addi	a4,a4,-1568 # 8023f9e8 <bcache+0x8268>
    80003010:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003014:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003018:	00234497          	auipc	s1,0x234
    8000301c:	78048493          	addi	s1,s1,1920 # 80237798 <bcache+0x18>
    b->next = bcache.head.next;
    80003020:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003022:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003024:	00005a17          	auipc	s4,0x5
    80003028:	51ca0a13          	addi	s4,s4,1308 # 80008540 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000302c:	2b893783          	ld	a5,696(s2)
    80003030:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003032:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003036:	85d2                	mv	a1,s4
    80003038:	01048513          	addi	a0,s1,16
    8000303c:	00001097          	auipc	ra,0x1
    80003040:	4b0080e7          	jalr	1200(ra) # 800044ec <initsleeplock>
    bcache.head.next->prev = b;
    80003044:	2b893783          	ld	a5,696(s2)
    80003048:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000304a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304e:	45848493          	addi	s1,s1,1112
    80003052:	fd349de3          	bne	s1,s3,8000302c <binit+0x54>
  }
}
    80003056:	70a2                	ld	ra,40(sp)
    80003058:	7402                	ld	s0,32(sp)
    8000305a:	64e2                	ld	s1,24(sp)
    8000305c:	6942                	ld	s2,16(sp)
    8000305e:	69a2                	ld	s3,8(sp)
    80003060:	6a02                	ld	s4,0(sp)
    80003062:	6145                	addi	sp,sp,48
    80003064:	8082                	ret

0000000080003066 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	e84a                	sd	s2,16(sp)
    80003070:	e44e                	sd	s3,8(sp)
    80003072:	1800                	addi	s0,sp,48
    80003074:	89aa                	mv	s3,a0
    80003076:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003078:	00234517          	auipc	a0,0x234
    8000307c:	70850513          	addi	a0,a0,1800 # 80237780 <bcache>
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	cda080e7          	jalr	-806(ra) # 80000d5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003088:	0023d497          	auipc	s1,0x23d
    8000308c:	9b04b483          	ld	s1,-1616(s1) # 8023fa38 <bcache+0x82b8>
    80003090:	0023d797          	auipc	a5,0x23d
    80003094:	95878793          	addi	a5,a5,-1704 # 8023f9e8 <bcache+0x8268>
    80003098:	02f48f63          	beq	s1,a5,800030d6 <bread+0x70>
    8000309c:	873e                	mv	a4,a5
    8000309e:	a021                	j	800030a6 <bread+0x40>
    800030a0:	68a4                	ld	s1,80(s1)
    800030a2:	02e48a63          	beq	s1,a4,800030d6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030a6:	449c                	lw	a5,8(s1)
    800030a8:	ff379ce3          	bne	a5,s3,800030a0 <bread+0x3a>
    800030ac:	44dc                	lw	a5,12(s1)
    800030ae:	ff2799e3          	bne	a5,s2,800030a0 <bread+0x3a>
      b->refcnt++;
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	2785                	addiw	a5,a5,1
    800030b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030b8:	00234517          	auipc	a0,0x234
    800030bc:	6c850513          	addi	a0,a0,1736 # 80237780 <bcache>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	d4e080e7          	jalr	-690(ra) # 80000e0e <release>
      acquiresleep(&b->lock);
    800030c8:	01048513          	addi	a0,s1,16
    800030cc:	00001097          	auipc	ra,0x1
    800030d0:	45a080e7          	jalr	1114(ra) # 80004526 <acquiresleep>
      return b;
    800030d4:	a8b9                	j	80003132 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d6:	0023d497          	auipc	s1,0x23d
    800030da:	95a4b483          	ld	s1,-1702(s1) # 8023fa30 <bcache+0x82b0>
    800030de:	0023d797          	auipc	a5,0x23d
    800030e2:	90a78793          	addi	a5,a5,-1782 # 8023f9e8 <bcache+0x8268>
    800030e6:	00f48863          	beq	s1,a5,800030f6 <bread+0x90>
    800030ea:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030ec:	40bc                	lw	a5,64(s1)
    800030ee:	cf81                	beqz	a5,80003106 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f0:	64a4                	ld	s1,72(s1)
    800030f2:	fee49de3          	bne	s1,a4,800030ec <bread+0x86>
  panic("bget: no buffers");
    800030f6:	00005517          	auipc	a0,0x5
    800030fa:	45250513          	addi	a0,a0,1106 # 80008548 <syscalls+0xc0>
    800030fe:	ffffd097          	auipc	ra,0xffffd
    80003102:	44a080e7          	jalr	1098(ra) # 80000548 <panic>
      b->dev = dev;
    80003106:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000310a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000310e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003112:	4785                	li	a5,1
    80003114:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003116:	00234517          	auipc	a0,0x234
    8000311a:	66a50513          	addi	a0,a0,1642 # 80237780 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	cf0080e7          	jalr	-784(ra) # 80000e0e <release>
      acquiresleep(&b->lock);
    80003126:	01048513          	addi	a0,s1,16
    8000312a:	00001097          	auipc	ra,0x1
    8000312e:	3fc080e7          	jalr	1020(ra) # 80004526 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003132:	409c                	lw	a5,0(s1)
    80003134:	cb89                	beqz	a5,80003146 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003136:	8526                	mv	a0,s1
    80003138:	70a2                	ld	ra,40(sp)
    8000313a:	7402                	ld	s0,32(sp)
    8000313c:	64e2                	ld	s1,24(sp)
    8000313e:	6942                	ld	s2,16(sp)
    80003140:	69a2                	ld	s3,8(sp)
    80003142:	6145                	addi	sp,sp,48
    80003144:	8082                	ret
    virtio_disk_rw(b, 0);
    80003146:	4581                	li	a1,0
    80003148:	8526                	mv	a0,s1
    8000314a:	00003097          	auipc	ra,0x3
    8000314e:	f32080e7          	jalr	-206(ra) # 8000607c <virtio_disk_rw>
    b->valid = 1;
    80003152:	4785                	li	a5,1
    80003154:	c09c                	sw	a5,0(s1)
  return b;
    80003156:	b7c5                	j	80003136 <bread+0xd0>

0000000080003158 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	e426                	sd	s1,8(sp)
    80003160:	1000                	addi	s0,sp,32
    80003162:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003164:	0541                	addi	a0,a0,16
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	45a080e7          	jalr	1114(ra) # 800045c0 <holdingsleep>
    8000316e:	cd01                	beqz	a0,80003186 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003170:	4585                	li	a1,1
    80003172:	8526                	mv	a0,s1
    80003174:	00003097          	auipc	ra,0x3
    80003178:	f08080e7          	jalr	-248(ra) # 8000607c <virtio_disk_rw>
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret
    panic("bwrite");
    80003186:	00005517          	auipc	a0,0x5
    8000318a:	3da50513          	addi	a0,a0,986 # 80008560 <syscalls+0xd8>
    8000318e:	ffffd097          	auipc	ra,0xffffd
    80003192:	3ba080e7          	jalr	954(ra) # 80000548 <panic>

0000000080003196 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031a4:	01050913          	addi	s2,a0,16
    800031a8:	854a                	mv	a0,s2
    800031aa:	00001097          	auipc	ra,0x1
    800031ae:	416080e7          	jalr	1046(ra) # 800045c0 <holdingsleep>
    800031b2:	c92d                	beqz	a0,80003224 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031b4:	854a                	mv	a0,s2
    800031b6:	00001097          	auipc	ra,0x1
    800031ba:	3c6080e7          	jalr	966(ra) # 8000457c <releasesleep>

  acquire(&bcache.lock);
    800031be:	00234517          	auipc	a0,0x234
    800031c2:	5c250513          	addi	a0,a0,1474 # 80237780 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	b94080e7          	jalr	-1132(ra) # 80000d5a <acquire>
  b->refcnt--;
    800031ce:	40bc                	lw	a5,64(s1)
    800031d0:	37fd                	addiw	a5,a5,-1
    800031d2:	0007871b          	sext.w	a4,a5
    800031d6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031d8:	eb05                	bnez	a4,80003208 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031da:	68bc                	ld	a5,80(s1)
    800031dc:	64b8                	ld	a4,72(s1)
    800031de:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031e0:	64bc                	ld	a5,72(s1)
    800031e2:	68b8                	ld	a4,80(s1)
    800031e4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031e6:	0023c797          	auipc	a5,0x23c
    800031ea:	59a78793          	addi	a5,a5,1434 # 8023f780 <bcache+0x8000>
    800031ee:	2b87b703          	ld	a4,696(a5)
    800031f2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031f4:	0023c717          	auipc	a4,0x23c
    800031f8:	7f470713          	addi	a4,a4,2036 # 8023f9e8 <bcache+0x8268>
    800031fc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031fe:	2b87b703          	ld	a4,696(a5)
    80003202:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003204:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003208:	00234517          	auipc	a0,0x234
    8000320c:	57850513          	addi	a0,a0,1400 # 80237780 <bcache>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	bfe080e7          	jalr	-1026(ra) # 80000e0e <release>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6902                	ld	s2,0(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret
    panic("brelse");
    80003224:	00005517          	auipc	a0,0x5
    80003228:	34450513          	addi	a0,a0,836 # 80008568 <syscalls+0xe0>
    8000322c:	ffffd097          	auipc	ra,0xffffd
    80003230:	31c080e7          	jalr	796(ra) # 80000548 <panic>

0000000080003234 <bpin>:

void
bpin(struct buf *b) {
    80003234:	1101                	addi	sp,sp,-32
    80003236:	ec06                	sd	ra,24(sp)
    80003238:	e822                	sd	s0,16(sp)
    8000323a:	e426                	sd	s1,8(sp)
    8000323c:	1000                	addi	s0,sp,32
    8000323e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003240:	00234517          	auipc	a0,0x234
    80003244:	54050513          	addi	a0,a0,1344 # 80237780 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	b12080e7          	jalr	-1262(ra) # 80000d5a <acquire>
  b->refcnt++;
    80003250:	40bc                	lw	a5,64(s1)
    80003252:	2785                	addiw	a5,a5,1
    80003254:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003256:	00234517          	auipc	a0,0x234
    8000325a:	52a50513          	addi	a0,a0,1322 # 80237780 <bcache>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	bb0080e7          	jalr	-1104(ra) # 80000e0e <release>
}
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <bunpin>:

void
bunpin(struct buf *b) {
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	1000                	addi	s0,sp,32
    8000327a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000327c:	00234517          	auipc	a0,0x234
    80003280:	50450513          	addi	a0,a0,1284 # 80237780 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	ad6080e7          	jalr	-1322(ra) # 80000d5a <acquire>
  b->refcnt--;
    8000328c:	40bc                	lw	a5,64(s1)
    8000328e:	37fd                	addiw	a5,a5,-1
    80003290:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003292:	00234517          	auipc	a0,0x234
    80003296:	4ee50513          	addi	a0,a0,1262 # 80237780 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	b74080e7          	jalr	-1164(ra) # 80000e0e <release>
}
    800032a2:	60e2                	ld	ra,24(sp)
    800032a4:	6442                	ld	s0,16(sp)
    800032a6:	64a2                	ld	s1,8(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	e04a                	sd	s2,0(sp)
    800032b6:	1000                	addi	s0,sp,32
    800032b8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032ba:	00d5d59b          	srliw	a1,a1,0xd
    800032be:	0023d797          	auipc	a5,0x23d
    800032c2:	b9e7a783          	lw	a5,-1122(a5) # 8023fe5c <sb+0x1c>
    800032c6:	9dbd                	addw	a1,a1,a5
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	d9e080e7          	jalr	-610(ra) # 80003066 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032d0:	0074f713          	andi	a4,s1,7
    800032d4:	4785                	li	a5,1
    800032d6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032da:	14ce                	slli	s1,s1,0x33
    800032dc:	90d9                	srli	s1,s1,0x36
    800032de:	00950733          	add	a4,a0,s1
    800032e2:	05874703          	lbu	a4,88(a4)
    800032e6:	00e7f6b3          	and	a3,a5,a4
    800032ea:	c69d                	beqz	a3,80003318 <bfree+0x6c>
    800032ec:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032ee:	94aa                	add	s1,s1,a0
    800032f0:	fff7c793          	not	a5,a5
    800032f4:	8ff9                	and	a5,a5,a4
    800032f6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	104080e7          	jalr	260(ra) # 800043fe <log_write>
  brelse(bp);
    80003302:	854a                	mv	a0,s2
    80003304:	00000097          	auipc	ra,0x0
    80003308:	e92080e7          	jalr	-366(ra) # 80003196 <brelse>
}
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	64a2                	ld	s1,8(sp)
    80003312:	6902                	ld	s2,0(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret
    panic("freeing free block");
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	25850513          	addi	a0,a0,600 # 80008570 <syscalls+0xe8>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	228080e7          	jalr	552(ra) # 80000548 <panic>

0000000080003328 <balloc>:
{
    80003328:	711d                	addi	sp,sp,-96
    8000332a:	ec86                	sd	ra,88(sp)
    8000332c:	e8a2                	sd	s0,80(sp)
    8000332e:	e4a6                	sd	s1,72(sp)
    80003330:	e0ca                	sd	s2,64(sp)
    80003332:	fc4e                	sd	s3,56(sp)
    80003334:	f852                	sd	s4,48(sp)
    80003336:	f456                	sd	s5,40(sp)
    80003338:	f05a                	sd	s6,32(sp)
    8000333a:	ec5e                	sd	s7,24(sp)
    8000333c:	e862                	sd	s8,16(sp)
    8000333e:	e466                	sd	s9,8(sp)
    80003340:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003342:	0023d797          	auipc	a5,0x23d
    80003346:	b027a783          	lw	a5,-1278(a5) # 8023fe44 <sb+0x4>
    8000334a:	cbd1                	beqz	a5,800033de <balloc+0xb6>
    8000334c:	8baa                	mv	s7,a0
    8000334e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003350:	0023db17          	auipc	s6,0x23d
    80003354:	af0b0b13          	addi	s6,s6,-1296 # 8023fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000335a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000335e:	6c89                	lui	s9,0x2
    80003360:	a831                	j	8000337c <balloc+0x54>
    brelse(bp);
    80003362:	854a                	mv	a0,s2
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e32080e7          	jalr	-462(ra) # 80003196 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000336c:	015c87bb          	addw	a5,s9,s5
    80003370:	00078a9b          	sext.w	s5,a5
    80003374:	004b2703          	lw	a4,4(s6)
    80003378:	06eaf363          	bgeu	s5,a4,800033de <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000337c:	41fad79b          	sraiw	a5,s5,0x1f
    80003380:	0137d79b          	srliw	a5,a5,0x13
    80003384:	015787bb          	addw	a5,a5,s5
    80003388:	40d7d79b          	sraiw	a5,a5,0xd
    8000338c:	01cb2583          	lw	a1,28(s6)
    80003390:	9dbd                	addw	a1,a1,a5
    80003392:	855e                	mv	a0,s7
    80003394:	00000097          	auipc	ra,0x0
    80003398:	cd2080e7          	jalr	-814(ra) # 80003066 <bread>
    8000339c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000339e:	004b2503          	lw	a0,4(s6)
    800033a2:	000a849b          	sext.w	s1,s5
    800033a6:	8662                	mv	a2,s8
    800033a8:	faa4fde3          	bgeu	s1,a0,80003362 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033ac:	41f6579b          	sraiw	a5,a2,0x1f
    800033b0:	01d7d69b          	srliw	a3,a5,0x1d
    800033b4:	00c6873b          	addw	a4,a3,a2
    800033b8:	00777793          	andi	a5,a4,7
    800033bc:	9f95                	subw	a5,a5,a3
    800033be:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033c2:	4037571b          	sraiw	a4,a4,0x3
    800033c6:	00e906b3          	add	a3,s2,a4
    800033ca:	0586c683          	lbu	a3,88(a3)
    800033ce:	00d7f5b3          	and	a1,a5,a3
    800033d2:	cd91                	beqz	a1,800033ee <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d4:	2605                	addiw	a2,a2,1
    800033d6:	2485                	addiw	s1,s1,1
    800033d8:	fd4618e3          	bne	a2,s4,800033a8 <balloc+0x80>
    800033dc:	b759                	j	80003362 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033de:	00005517          	auipc	a0,0x5
    800033e2:	1aa50513          	addi	a0,a0,426 # 80008588 <syscalls+0x100>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	162080e7          	jalr	354(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ee:	974a                	add	a4,a4,s2
    800033f0:	8fd5                	or	a5,a5,a3
    800033f2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	006080e7          	jalr	6(ra) # 800043fe <log_write>
        brelse(bp);
    80003400:	854a                	mv	a0,s2
    80003402:	00000097          	auipc	ra,0x0
    80003406:	d94080e7          	jalr	-620(ra) # 80003196 <brelse>
  bp = bread(dev, bno);
    8000340a:	85a6                	mv	a1,s1
    8000340c:	855e                	mv	a0,s7
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	c58080e7          	jalr	-936(ra) # 80003066 <bread>
    80003416:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003418:	40000613          	li	a2,1024
    8000341c:	4581                	li	a1,0
    8000341e:	05850513          	addi	a0,a0,88
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	a34080e7          	jalr	-1484(ra) # 80000e56 <memset>
  log_write(bp);
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	fd2080e7          	jalr	-46(ra) # 800043fe <log_write>
  brelse(bp);
    80003434:	854a                	mv	a0,s2
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	d60080e7          	jalr	-672(ra) # 80003196 <brelse>
}
    8000343e:	8526                	mv	a0,s1
    80003440:	60e6                	ld	ra,88(sp)
    80003442:	6446                	ld	s0,80(sp)
    80003444:	64a6                	ld	s1,72(sp)
    80003446:	6906                	ld	s2,64(sp)
    80003448:	79e2                	ld	s3,56(sp)
    8000344a:	7a42                	ld	s4,48(sp)
    8000344c:	7aa2                	ld	s5,40(sp)
    8000344e:	7b02                	ld	s6,32(sp)
    80003450:	6be2                	ld	s7,24(sp)
    80003452:	6c42                	ld	s8,16(sp)
    80003454:	6ca2                	ld	s9,8(sp)
    80003456:	6125                	addi	sp,sp,96
    80003458:	8082                	ret

000000008000345a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000345a:	7179                	addi	sp,sp,-48
    8000345c:	f406                	sd	ra,40(sp)
    8000345e:	f022                	sd	s0,32(sp)
    80003460:	ec26                	sd	s1,24(sp)
    80003462:	e84a                	sd	s2,16(sp)
    80003464:	e44e                	sd	s3,8(sp)
    80003466:	e052                	sd	s4,0(sp)
    80003468:	1800                	addi	s0,sp,48
    8000346a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000346c:	47ad                	li	a5,11
    8000346e:	04b7fe63          	bgeu	a5,a1,800034ca <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003472:	ff45849b          	addiw	s1,a1,-12
    80003476:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000347a:	0ff00793          	li	a5,255
    8000347e:	0ae7e363          	bltu	a5,a4,80003524 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003482:	08052583          	lw	a1,128(a0)
    80003486:	c5ad                	beqz	a1,800034f0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003488:	00092503          	lw	a0,0(s2)
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	bda080e7          	jalr	-1062(ra) # 80003066 <bread>
    80003494:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003496:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000349a:	02049593          	slli	a1,s1,0x20
    8000349e:	9181                	srli	a1,a1,0x20
    800034a0:	058a                	slli	a1,a1,0x2
    800034a2:	00b784b3          	add	s1,a5,a1
    800034a6:	0004a983          	lw	s3,0(s1)
    800034aa:	04098d63          	beqz	s3,80003504 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034ae:	8552                	mv	a0,s4
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	ce6080e7          	jalr	-794(ra) # 80003196 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034b8:	854e                	mv	a0,s3
    800034ba:	70a2                	ld	ra,40(sp)
    800034bc:	7402                	ld	s0,32(sp)
    800034be:	64e2                	ld	s1,24(sp)
    800034c0:	6942                	ld	s2,16(sp)
    800034c2:	69a2                	ld	s3,8(sp)
    800034c4:	6a02                	ld	s4,0(sp)
    800034c6:	6145                	addi	sp,sp,48
    800034c8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034ca:	02059493          	slli	s1,a1,0x20
    800034ce:	9081                	srli	s1,s1,0x20
    800034d0:	048a                	slli	s1,s1,0x2
    800034d2:	94aa                	add	s1,s1,a0
    800034d4:	0504a983          	lw	s3,80(s1)
    800034d8:	fe0990e3          	bnez	s3,800034b8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034dc:	4108                	lw	a0,0(a0)
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e4a080e7          	jalr	-438(ra) # 80003328 <balloc>
    800034e6:	0005099b          	sext.w	s3,a0
    800034ea:	0534a823          	sw	s3,80(s1)
    800034ee:	b7e9                	j	800034b8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034f0:	4108                	lw	a0,0(a0)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e36080e7          	jalr	-458(ra) # 80003328 <balloc>
    800034fa:	0005059b          	sext.w	a1,a0
    800034fe:	08b92023          	sw	a1,128(s2)
    80003502:	b759                	j	80003488 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003504:	00092503          	lw	a0,0(s2)
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	e20080e7          	jalr	-480(ra) # 80003328 <balloc>
    80003510:	0005099b          	sext.w	s3,a0
    80003514:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003518:	8552                	mv	a0,s4
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	ee4080e7          	jalr	-284(ra) # 800043fe <log_write>
    80003522:	b771                	j	800034ae <bmap+0x54>
  panic("bmap: out of range");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	07c50513          	addi	a0,a0,124 # 800085a0 <syscalls+0x118>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	01c080e7          	jalr	28(ra) # 80000548 <panic>

0000000080003534 <iget>:
{
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	e052                	sd	s4,0(sp)
    80003542:	1800                	addi	s0,sp,48
    80003544:	89aa                	mv	s3,a0
    80003546:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003548:	0023d517          	auipc	a0,0x23d
    8000354c:	91850513          	addi	a0,a0,-1768 # 8023fe60 <icache>
    80003550:	ffffe097          	auipc	ra,0xffffe
    80003554:	80a080e7          	jalr	-2038(ra) # 80000d5a <acquire>
  empty = 0;
    80003558:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000355a:	0023d497          	auipc	s1,0x23d
    8000355e:	91e48493          	addi	s1,s1,-1762 # 8023fe78 <icache+0x18>
    80003562:	0023e697          	auipc	a3,0x23e
    80003566:	3a668693          	addi	a3,a3,934 # 80241908 <log>
    8000356a:	a039                	j	80003578 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000356c:	02090b63          	beqz	s2,800035a2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003570:	08848493          	addi	s1,s1,136
    80003574:	02d48a63          	beq	s1,a3,800035a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003578:	449c                	lw	a5,8(s1)
    8000357a:	fef059e3          	blez	a5,8000356c <iget+0x38>
    8000357e:	4098                	lw	a4,0(s1)
    80003580:	ff3716e3          	bne	a4,s3,8000356c <iget+0x38>
    80003584:	40d8                	lw	a4,4(s1)
    80003586:	ff4713e3          	bne	a4,s4,8000356c <iget+0x38>
      ip->ref++;
    8000358a:	2785                	addiw	a5,a5,1
    8000358c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000358e:	0023d517          	auipc	a0,0x23d
    80003592:	8d250513          	addi	a0,a0,-1838 # 8023fe60 <icache>
    80003596:	ffffe097          	auipc	ra,0xffffe
    8000359a:	878080e7          	jalr	-1928(ra) # 80000e0e <release>
      return ip;
    8000359e:	8926                	mv	s2,s1
    800035a0:	a03d                	j	800035ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035a2:	f7f9                	bnez	a5,80003570 <iget+0x3c>
    800035a4:	8926                	mv	s2,s1
    800035a6:	b7e9                	j	80003570 <iget+0x3c>
  if(empty == 0)
    800035a8:	02090c63          	beqz	s2,800035e0 <iget+0xac>
  ip->dev = dev;
    800035ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035b4:	4785                	li	a5,1
    800035b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035ba:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035be:	0023d517          	auipc	a0,0x23d
    800035c2:	8a250513          	addi	a0,a0,-1886 # 8023fe60 <icache>
    800035c6:	ffffe097          	auipc	ra,0xffffe
    800035ca:	848080e7          	jalr	-1976(ra) # 80000e0e <release>
}
    800035ce:	854a                	mv	a0,s2
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6a02                	ld	s4,0(sp)
    800035dc:	6145                	addi	sp,sp,48
    800035de:	8082                	ret
    panic("iget: no inodes");
    800035e0:	00005517          	auipc	a0,0x5
    800035e4:	fd850513          	addi	a0,a0,-40 # 800085b8 <syscalls+0x130>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	f60080e7          	jalr	-160(ra) # 80000548 <panic>

00000000800035f0 <fsinit>:
fsinit(int dev) {
    800035f0:	7179                	addi	sp,sp,-48
    800035f2:	f406                	sd	ra,40(sp)
    800035f4:	f022                	sd	s0,32(sp)
    800035f6:	ec26                	sd	s1,24(sp)
    800035f8:	e84a                	sd	s2,16(sp)
    800035fa:	e44e                	sd	s3,8(sp)
    800035fc:	1800                	addi	s0,sp,48
    800035fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003600:	4585                	li	a1,1
    80003602:	00000097          	auipc	ra,0x0
    80003606:	a64080e7          	jalr	-1436(ra) # 80003066 <bread>
    8000360a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000360c:	0023d997          	auipc	s3,0x23d
    80003610:	83498993          	addi	s3,s3,-1996 # 8023fe40 <sb>
    80003614:	02000613          	li	a2,32
    80003618:	05850593          	addi	a1,a0,88
    8000361c:	854e                	mv	a0,s3
    8000361e:	ffffe097          	auipc	ra,0xffffe
    80003622:	898080e7          	jalr	-1896(ra) # 80000eb6 <memmove>
  brelse(bp);
    80003626:	8526                	mv	a0,s1
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	b6e080e7          	jalr	-1170(ra) # 80003196 <brelse>
  if(sb.magic != FSMAGIC)
    80003630:	0009a703          	lw	a4,0(s3)
    80003634:	102037b7          	lui	a5,0x10203
    80003638:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000363c:	02f71263          	bne	a4,a5,80003660 <fsinit+0x70>
  initlog(dev, &sb);
    80003640:	0023d597          	auipc	a1,0x23d
    80003644:	80058593          	addi	a1,a1,-2048 # 8023fe40 <sb>
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	b3c080e7          	jalr	-1220(ra) # 80004186 <initlog>
}
    80003652:	70a2                	ld	ra,40(sp)
    80003654:	7402                	ld	s0,32(sp)
    80003656:	64e2                	ld	s1,24(sp)
    80003658:	6942                	ld	s2,16(sp)
    8000365a:	69a2                	ld	s3,8(sp)
    8000365c:	6145                	addi	sp,sp,48
    8000365e:	8082                	ret
    panic("invalid file system");
    80003660:	00005517          	auipc	a0,0x5
    80003664:	f6850513          	addi	a0,a0,-152 # 800085c8 <syscalls+0x140>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	ee0080e7          	jalr	-288(ra) # 80000548 <panic>

0000000080003670 <iinit>:
{
    80003670:	7179                	addi	sp,sp,-48
    80003672:	f406                	sd	ra,40(sp)
    80003674:	f022                	sd	s0,32(sp)
    80003676:	ec26                	sd	s1,24(sp)
    80003678:	e84a                	sd	s2,16(sp)
    8000367a:	e44e                	sd	s3,8(sp)
    8000367c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000367e:	00005597          	auipc	a1,0x5
    80003682:	f6258593          	addi	a1,a1,-158 # 800085e0 <syscalls+0x158>
    80003686:	0023c517          	auipc	a0,0x23c
    8000368a:	7da50513          	addi	a0,a0,2010 # 8023fe60 <icache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	63c080e7          	jalr	1596(ra) # 80000cca <initlock>
  for(i = 0; i < NINODE; i++) {
    80003696:	0023c497          	auipc	s1,0x23c
    8000369a:	7f248493          	addi	s1,s1,2034 # 8023fe88 <icache+0x28>
    8000369e:	0023e997          	auipc	s3,0x23e
    800036a2:	27a98993          	addi	s3,s3,634 # 80241918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036a6:	00005917          	auipc	s2,0x5
    800036aa:	f4290913          	addi	s2,s2,-190 # 800085e8 <syscalls+0x160>
    800036ae:	85ca                	mv	a1,s2
    800036b0:	8526                	mv	a0,s1
    800036b2:	00001097          	auipc	ra,0x1
    800036b6:	e3a080e7          	jalr	-454(ra) # 800044ec <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036ba:	08848493          	addi	s1,s1,136
    800036be:	ff3498e3          	bne	s1,s3,800036ae <iinit+0x3e>
}
    800036c2:	70a2                	ld	ra,40(sp)
    800036c4:	7402                	ld	s0,32(sp)
    800036c6:	64e2                	ld	s1,24(sp)
    800036c8:	6942                	ld	s2,16(sp)
    800036ca:	69a2                	ld	s3,8(sp)
    800036cc:	6145                	addi	sp,sp,48
    800036ce:	8082                	ret

00000000800036d0 <ialloc>:
{
    800036d0:	715d                	addi	sp,sp,-80
    800036d2:	e486                	sd	ra,72(sp)
    800036d4:	e0a2                	sd	s0,64(sp)
    800036d6:	fc26                	sd	s1,56(sp)
    800036d8:	f84a                	sd	s2,48(sp)
    800036da:	f44e                	sd	s3,40(sp)
    800036dc:	f052                	sd	s4,32(sp)
    800036de:	ec56                	sd	s5,24(sp)
    800036e0:	e85a                	sd	s6,16(sp)
    800036e2:	e45e                	sd	s7,8(sp)
    800036e4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036e6:	0023c717          	auipc	a4,0x23c
    800036ea:	76672703          	lw	a4,1894(a4) # 8023fe4c <sb+0xc>
    800036ee:	4785                	li	a5,1
    800036f0:	04e7fa63          	bgeu	a5,a4,80003744 <ialloc+0x74>
    800036f4:	8aaa                	mv	s5,a0
    800036f6:	8bae                	mv	s7,a1
    800036f8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036fa:	0023ca17          	auipc	s4,0x23c
    800036fe:	746a0a13          	addi	s4,s4,1862 # 8023fe40 <sb>
    80003702:	00048b1b          	sext.w	s6,s1
    80003706:	0044d593          	srli	a1,s1,0x4
    8000370a:	018a2783          	lw	a5,24(s4)
    8000370e:	9dbd                	addw	a1,a1,a5
    80003710:	8556                	mv	a0,s5
    80003712:	00000097          	auipc	ra,0x0
    80003716:	954080e7          	jalr	-1708(ra) # 80003066 <bread>
    8000371a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000371c:	05850993          	addi	s3,a0,88
    80003720:	00f4f793          	andi	a5,s1,15
    80003724:	079a                	slli	a5,a5,0x6
    80003726:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003728:	00099783          	lh	a5,0(s3)
    8000372c:	c785                	beqz	a5,80003754 <ialloc+0x84>
    brelse(bp);
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	a68080e7          	jalr	-1432(ra) # 80003196 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003736:	0485                	addi	s1,s1,1
    80003738:	00ca2703          	lw	a4,12(s4)
    8000373c:	0004879b          	sext.w	a5,s1
    80003740:	fce7e1e3          	bltu	a5,a4,80003702 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003744:	00005517          	auipc	a0,0x5
    80003748:	eac50513          	addi	a0,a0,-340 # 800085f0 <syscalls+0x168>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	dfc080e7          	jalr	-516(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003754:	04000613          	li	a2,64
    80003758:	4581                	li	a1,0
    8000375a:	854e                	mv	a0,s3
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	6fa080e7          	jalr	1786(ra) # 80000e56 <memset>
      dip->type = type;
    80003764:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	c94080e7          	jalr	-876(ra) # 800043fe <log_write>
      brelse(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00000097          	auipc	ra,0x0
    80003778:	a22080e7          	jalr	-1502(ra) # 80003196 <brelse>
      return iget(dev, inum);
    8000377c:	85da                	mv	a1,s6
    8000377e:	8556                	mv	a0,s5
    80003780:	00000097          	auipc	ra,0x0
    80003784:	db4080e7          	jalr	-588(ra) # 80003534 <iget>
}
    80003788:	60a6                	ld	ra,72(sp)
    8000378a:	6406                	ld	s0,64(sp)
    8000378c:	74e2                	ld	s1,56(sp)
    8000378e:	7942                	ld	s2,48(sp)
    80003790:	79a2                	ld	s3,40(sp)
    80003792:	7a02                	ld	s4,32(sp)
    80003794:	6ae2                	ld	s5,24(sp)
    80003796:	6b42                	ld	s6,16(sp)
    80003798:	6ba2                	ld	s7,8(sp)
    8000379a:	6161                	addi	sp,sp,80
    8000379c:	8082                	ret

000000008000379e <iupdate>:
{
    8000379e:	1101                	addi	sp,sp,-32
    800037a0:	ec06                	sd	ra,24(sp)
    800037a2:	e822                	sd	s0,16(sp)
    800037a4:	e426                	sd	s1,8(sp)
    800037a6:	e04a                	sd	s2,0(sp)
    800037a8:	1000                	addi	s0,sp,32
    800037aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ac:	415c                	lw	a5,4(a0)
    800037ae:	0047d79b          	srliw	a5,a5,0x4
    800037b2:	0023c597          	auipc	a1,0x23c
    800037b6:	6a65a583          	lw	a1,1702(a1) # 8023fe58 <sb+0x18>
    800037ba:	9dbd                	addw	a1,a1,a5
    800037bc:	4108                	lw	a0,0(a0)
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	8a8080e7          	jalr	-1880(ra) # 80003066 <bread>
    800037c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037c8:	05850793          	addi	a5,a0,88
    800037cc:	40c8                	lw	a0,4(s1)
    800037ce:	893d                	andi	a0,a0,15
    800037d0:	051a                	slli	a0,a0,0x6
    800037d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037d4:	04449703          	lh	a4,68(s1)
    800037d8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037dc:	04649703          	lh	a4,70(s1)
    800037e0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037e4:	04849703          	lh	a4,72(s1)
    800037e8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ec:	04a49703          	lh	a4,74(s1)
    800037f0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037f4:	44f8                	lw	a4,76(s1)
    800037f6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037f8:	03400613          	li	a2,52
    800037fc:	05048593          	addi	a1,s1,80
    80003800:	0531                	addi	a0,a0,12
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	6b4080e7          	jalr	1716(ra) # 80000eb6 <memmove>
  log_write(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	bf2080e7          	jalr	-1038(ra) # 800043fe <log_write>
  brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	980080e7          	jalr	-1664(ra) # 80003196 <brelse>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret

000000008000382a <idup>:
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	1000                	addi	s0,sp,32
    80003834:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003836:	0023c517          	auipc	a0,0x23c
    8000383a:	62a50513          	addi	a0,a0,1578 # 8023fe60 <icache>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	51c080e7          	jalr	1308(ra) # 80000d5a <acquire>
  ip->ref++;
    80003846:	449c                	lw	a5,8(s1)
    80003848:	2785                	addiw	a5,a5,1
    8000384a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000384c:	0023c517          	auipc	a0,0x23c
    80003850:	61450513          	addi	a0,a0,1556 # 8023fe60 <icache>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	5ba080e7          	jalr	1466(ra) # 80000e0e <release>
}
    8000385c:	8526                	mv	a0,s1
    8000385e:	60e2                	ld	ra,24(sp)
    80003860:	6442                	ld	s0,16(sp)
    80003862:	64a2                	ld	s1,8(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret

0000000080003868 <ilock>:
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	e04a                	sd	s2,0(sp)
    80003872:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003874:	c115                	beqz	a0,80003898 <ilock+0x30>
    80003876:	84aa                	mv	s1,a0
    80003878:	451c                	lw	a5,8(a0)
    8000387a:	00f05f63          	blez	a5,80003898 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000387e:	0541                	addi	a0,a0,16
    80003880:	00001097          	auipc	ra,0x1
    80003884:	ca6080e7          	jalr	-858(ra) # 80004526 <acquiresleep>
  if(ip->valid == 0){
    80003888:	40bc                	lw	a5,64(s1)
    8000388a:	cf99                	beqz	a5,800038a8 <ilock+0x40>
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6902                	ld	s2,0(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret
    panic("ilock");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	d7050513          	addi	a0,a0,-656 # 80008608 <syscalls+0x180>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	ca8080e7          	jalr	-856(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038a8:	40dc                	lw	a5,4(s1)
    800038aa:	0047d79b          	srliw	a5,a5,0x4
    800038ae:	0023c597          	auipc	a1,0x23c
    800038b2:	5aa5a583          	lw	a1,1450(a1) # 8023fe58 <sb+0x18>
    800038b6:	9dbd                	addw	a1,a1,a5
    800038b8:	4088                	lw	a0,0(s1)
    800038ba:	fffff097          	auipc	ra,0xfffff
    800038be:	7ac080e7          	jalr	1964(ra) # 80003066 <bread>
    800038c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c4:	05850593          	addi	a1,a0,88
    800038c8:	40dc                	lw	a5,4(s1)
    800038ca:	8bbd                	andi	a5,a5,15
    800038cc:	079a                	slli	a5,a5,0x6
    800038ce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038d0:	00059783          	lh	a5,0(a1)
    800038d4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038d8:	00259783          	lh	a5,2(a1)
    800038dc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038e0:	00459783          	lh	a5,4(a1)
    800038e4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038e8:	00659783          	lh	a5,6(a1)
    800038ec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038f0:	459c                	lw	a5,8(a1)
    800038f2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038f4:	03400613          	li	a2,52
    800038f8:	05b1                	addi	a1,a1,12
    800038fa:	05048513          	addi	a0,s1,80
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	5b8080e7          	jalr	1464(ra) # 80000eb6 <memmove>
    brelse(bp);
    80003906:	854a                	mv	a0,s2
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	88e080e7          	jalr	-1906(ra) # 80003196 <brelse>
    ip->valid = 1;
    80003910:	4785                	li	a5,1
    80003912:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003914:	04449783          	lh	a5,68(s1)
    80003918:	fbb5                	bnez	a5,8000388c <ilock+0x24>
      panic("ilock: no type");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	cf650513          	addi	a0,a0,-778 # 80008610 <syscalls+0x188>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	c26080e7          	jalr	-986(ra) # 80000548 <panic>

000000008000392a <iunlock>:
{
    8000392a:	1101                	addi	sp,sp,-32
    8000392c:	ec06                	sd	ra,24(sp)
    8000392e:	e822                	sd	s0,16(sp)
    80003930:	e426                	sd	s1,8(sp)
    80003932:	e04a                	sd	s2,0(sp)
    80003934:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003936:	c905                	beqz	a0,80003966 <iunlock+0x3c>
    80003938:	84aa                	mv	s1,a0
    8000393a:	01050913          	addi	s2,a0,16
    8000393e:	854a                	mv	a0,s2
    80003940:	00001097          	auipc	ra,0x1
    80003944:	c80080e7          	jalr	-896(ra) # 800045c0 <holdingsleep>
    80003948:	cd19                	beqz	a0,80003966 <iunlock+0x3c>
    8000394a:	449c                	lw	a5,8(s1)
    8000394c:	00f05d63          	blez	a5,80003966 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	c2a080e7          	jalr	-982(ra) # 8000457c <releasesleep>
}
    8000395a:	60e2                	ld	ra,24(sp)
    8000395c:	6442                	ld	s0,16(sp)
    8000395e:	64a2                	ld	s1,8(sp)
    80003960:	6902                	ld	s2,0(sp)
    80003962:	6105                	addi	sp,sp,32
    80003964:	8082                	ret
    panic("iunlock");
    80003966:	00005517          	auipc	a0,0x5
    8000396a:	cba50513          	addi	a0,a0,-838 # 80008620 <syscalls+0x198>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	bda080e7          	jalr	-1062(ra) # 80000548 <panic>

0000000080003976 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003976:	7179                	addi	sp,sp,-48
    80003978:	f406                	sd	ra,40(sp)
    8000397a:	f022                	sd	s0,32(sp)
    8000397c:	ec26                	sd	s1,24(sp)
    8000397e:	e84a                	sd	s2,16(sp)
    80003980:	e44e                	sd	s3,8(sp)
    80003982:	e052                	sd	s4,0(sp)
    80003984:	1800                	addi	s0,sp,48
    80003986:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003988:	05050493          	addi	s1,a0,80
    8000398c:	08050913          	addi	s2,a0,128
    80003990:	a021                	j	80003998 <itrunc+0x22>
    80003992:	0491                	addi	s1,s1,4
    80003994:	01248d63          	beq	s1,s2,800039ae <itrunc+0x38>
    if(ip->addrs[i]){
    80003998:	408c                	lw	a1,0(s1)
    8000399a:	dde5                	beqz	a1,80003992 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000399c:	0009a503          	lw	a0,0(s3)
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	90c080e7          	jalr	-1780(ra) # 800032ac <bfree>
      ip->addrs[i] = 0;
    800039a8:	0004a023          	sw	zero,0(s1)
    800039ac:	b7dd                	j	80003992 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039ae:	0809a583          	lw	a1,128(s3)
    800039b2:	e185                	bnez	a1,800039d2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039b4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039b8:	854e                	mv	a0,s3
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	de4080e7          	jalr	-540(ra) # 8000379e <iupdate>
}
    800039c2:	70a2                	ld	ra,40(sp)
    800039c4:	7402                	ld	s0,32(sp)
    800039c6:	64e2                	ld	s1,24(sp)
    800039c8:	6942                	ld	s2,16(sp)
    800039ca:	69a2                	ld	s3,8(sp)
    800039cc:	6a02                	ld	s4,0(sp)
    800039ce:	6145                	addi	sp,sp,48
    800039d0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039d2:	0009a503          	lw	a0,0(s3)
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	690080e7          	jalr	1680(ra) # 80003066 <bread>
    800039de:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039e0:	05850493          	addi	s1,a0,88
    800039e4:	45850913          	addi	s2,a0,1112
    800039e8:	a811                	j	800039fc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039ea:	0009a503          	lw	a0,0(s3)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	8be080e7          	jalr	-1858(ra) # 800032ac <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039f6:	0491                	addi	s1,s1,4
    800039f8:	01248563          	beq	s1,s2,80003a02 <itrunc+0x8c>
      if(a[j])
    800039fc:	408c                	lw	a1,0(s1)
    800039fe:	dde5                	beqz	a1,800039f6 <itrunc+0x80>
    80003a00:	b7ed                	j	800039ea <itrunc+0x74>
    brelse(bp);
    80003a02:	8552                	mv	a0,s4
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	792080e7          	jalr	1938(ra) # 80003196 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a0c:	0809a583          	lw	a1,128(s3)
    80003a10:	0009a503          	lw	a0,0(s3)
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	898080e7          	jalr	-1896(ra) # 800032ac <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a1c:	0809a023          	sw	zero,128(s3)
    80003a20:	bf51                	j	800039b4 <itrunc+0x3e>

0000000080003a22 <iput>:
{
    80003a22:	1101                	addi	sp,sp,-32
    80003a24:	ec06                	sd	ra,24(sp)
    80003a26:	e822                	sd	s0,16(sp)
    80003a28:	e426                	sd	s1,8(sp)
    80003a2a:	e04a                	sd	s2,0(sp)
    80003a2c:	1000                	addi	s0,sp,32
    80003a2e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a30:	0023c517          	auipc	a0,0x23c
    80003a34:	43050513          	addi	a0,a0,1072 # 8023fe60 <icache>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	322080e7          	jalr	802(ra) # 80000d5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a40:	4498                	lw	a4,8(s1)
    80003a42:	4785                	li	a5,1
    80003a44:	02f70363          	beq	a4,a5,80003a6a <iput+0x48>
  ip->ref--;
    80003a48:	449c                	lw	a5,8(s1)
    80003a4a:	37fd                	addiw	a5,a5,-1
    80003a4c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a4e:	0023c517          	auipc	a0,0x23c
    80003a52:	41250513          	addi	a0,a0,1042 # 8023fe60 <icache>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	3b8080e7          	jalr	952(ra) # 80000e0e <release>
}
    80003a5e:	60e2                	ld	ra,24(sp)
    80003a60:	6442                	ld	s0,16(sp)
    80003a62:	64a2                	ld	s1,8(sp)
    80003a64:	6902                	ld	s2,0(sp)
    80003a66:	6105                	addi	sp,sp,32
    80003a68:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a6a:	40bc                	lw	a5,64(s1)
    80003a6c:	dff1                	beqz	a5,80003a48 <iput+0x26>
    80003a6e:	04a49783          	lh	a5,74(s1)
    80003a72:	fbf9                	bnez	a5,80003a48 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a74:	01048913          	addi	s2,s1,16
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	aac080e7          	jalr	-1364(ra) # 80004526 <acquiresleep>
    release(&icache.lock);
    80003a82:	0023c517          	auipc	a0,0x23c
    80003a86:	3de50513          	addi	a0,a0,990 # 8023fe60 <icache>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	384080e7          	jalr	900(ra) # 80000e0e <release>
    itrunc(ip);
    80003a92:	8526                	mv	a0,s1
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	ee2080e7          	jalr	-286(ra) # 80003976 <itrunc>
    ip->type = 0;
    80003a9c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	cfc080e7          	jalr	-772(ra) # 8000379e <iupdate>
    ip->valid = 0;
    80003aaa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	00001097          	auipc	ra,0x1
    80003ab4:	acc080e7          	jalr	-1332(ra) # 8000457c <releasesleep>
    acquire(&icache.lock);
    80003ab8:	0023c517          	auipc	a0,0x23c
    80003abc:	3a850513          	addi	a0,a0,936 # 8023fe60 <icache>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	29a080e7          	jalr	666(ra) # 80000d5a <acquire>
    80003ac8:	b741                	j	80003a48 <iput+0x26>

0000000080003aca <iunlockput>:
{
    80003aca:	1101                	addi	sp,sp,-32
    80003acc:	ec06                	sd	ra,24(sp)
    80003ace:	e822                	sd	s0,16(sp)
    80003ad0:	e426                	sd	s1,8(sp)
    80003ad2:	1000                	addi	s0,sp,32
    80003ad4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	e54080e7          	jalr	-428(ra) # 8000392a <iunlock>
  iput(ip);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	f42080e7          	jalr	-190(ra) # 80003a22 <iput>
}
    80003ae8:	60e2                	ld	ra,24(sp)
    80003aea:	6442                	ld	s0,16(sp)
    80003aec:	64a2                	ld	s1,8(sp)
    80003aee:	6105                	addi	sp,sp,32
    80003af0:	8082                	ret

0000000080003af2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003af2:	1141                	addi	sp,sp,-16
    80003af4:	e422                	sd	s0,8(sp)
    80003af6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003af8:	411c                	lw	a5,0(a0)
    80003afa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003afc:	415c                	lw	a5,4(a0)
    80003afe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b00:	04451783          	lh	a5,68(a0)
    80003b04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b08:	04a51783          	lh	a5,74(a0)
    80003b0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b10:	04c56783          	lwu	a5,76(a0)
    80003b14:	e99c                	sd	a5,16(a1)
}
    80003b16:	6422                	ld	s0,8(sp)
    80003b18:	0141                	addi	sp,sp,16
    80003b1a:	8082                	ret

0000000080003b1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1c:	457c                	lw	a5,76(a0)
    80003b1e:	0ed7e963          	bltu	a5,a3,80003c10 <readi+0xf4>
{
    80003b22:	7159                	addi	sp,sp,-112
    80003b24:	f486                	sd	ra,104(sp)
    80003b26:	f0a2                	sd	s0,96(sp)
    80003b28:	eca6                	sd	s1,88(sp)
    80003b2a:	e8ca                	sd	s2,80(sp)
    80003b2c:	e4ce                	sd	s3,72(sp)
    80003b2e:	e0d2                	sd	s4,64(sp)
    80003b30:	fc56                	sd	s5,56(sp)
    80003b32:	f85a                	sd	s6,48(sp)
    80003b34:	f45e                	sd	s7,40(sp)
    80003b36:	f062                	sd	s8,32(sp)
    80003b38:	ec66                	sd	s9,24(sp)
    80003b3a:	e86a                	sd	s10,16(sp)
    80003b3c:	e46e                	sd	s11,8(sp)
    80003b3e:	1880                	addi	s0,sp,112
    80003b40:	8baa                	mv	s7,a0
    80003b42:	8c2e                	mv	s8,a1
    80003b44:	8ab2                	mv	s5,a2
    80003b46:	84b6                	mv	s1,a3
    80003b48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b4e:	0ad76063          	bltu	a4,a3,80003bee <readi+0xd2>
  if(off + n > ip->size)
    80003b52:	00e7f463          	bgeu	a5,a4,80003b5a <readi+0x3e>
    n = ip->size - off;
    80003b56:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	0a0b0963          	beqz	s6,80003c0c <readi+0xf0>
    80003b5e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b64:	5cfd                	li	s9,-1
    80003b66:	a82d                	j	80003ba0 <readi+0x84>
    80003b68:	020a1d93          	slli	s11,s4,0x20
    80003b6c:	020ddd93          	srli	s11,s11,0x20
    80003b70:	05890613          	addi	a2,s2,88
    80003b74:	86ee                	mv	a3,s11
    80003b76:	963a                	add	a2,a2,a4
    80003b78:	85d6                	mv	a1,s5
    80003b7a:	8562                	mv	a0,s8
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	a6e080e7          	jalr	-1426(ra) # 800025ea <either_copyout>
    80003b84:	05950d63          	beq	a0,s9,80003bde <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b88:	854a                	mv	a0,s2
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	60c080e7          	jalr	1548(ra) # 80003196 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b92:	013a09bb          	addw	s3,s4,s3
    80003b96:	009a04bb          	addw	s1,s4,s1
    80003b9a:	9aee                	add	s5,s5,s11
    80003b9c:	0569f763          	bgeu	s3,s6,80003bea <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ba0:	000ba903          	lw	s2,0(s7)
    80003ba4:	00a4d59b          	srliw	a1,s1,0xa
    80003ba8:	855e                	mv	a0,s7
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	8b0080e7          	jalr	-1872(ra) # 8000345a <bmap>
    80003bb2:	0005059b          	sext.w	a1,a0
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	4ae080e7          	jalr	1198(ra) # 80003066 <bread>
    80003bc0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc2:	3ff4f713          	andi	a4,s1,1023
    80003bc6:	40ed07bb          	subw	a5,s10,a4
    80003bca:	413b06bb          	subw	a3,s6,s3
    80003bce:	8a3e                	mv	s4,a5
    80003bd0:	2781                	sext.w	a5,a5
    80003bd2:	0006861b          	sext.w	a2,a3
    80003bd6:	f8f679e3          	bgeu	a2,a5,80003b68 <readi+0x4c>
    80003bda:	8a36                	mv	s4,a3
    80003bdc:	b771                	j	80003b68 <readi+0x4c>
      brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	5b6080e7          	jalr	1462(ra) # 80003196 <brelse>
      tot = -1;
    80003be8:	59fd                	li	s3,-1
  }
  return tot;
    80003bea:	0009851b          	sext.w	a0,s3
}
    80003bee:	70a6                	ld	ra,104(sp)
    80003bf0:	7406                	ld	s0,96(sp)
    80003bf2:	64e6                	ld	s1,88(sp)
    80003bf4:	6946                	ld	s2,80(sp)
    80003bf6:	69a6                	ld	s3,72(sp)
    80003bf8:	6a06                	ld	s4,64(sp)
    80003bfa:	7ae2                	ld	s5,56(sp)
    80003bfc:	7b42                	ld	s6,48(sp)
    80003bfe:	7ba2                	ld	s7,40(sp)
    80003c00:	7c02                	ld	s8,32(sp)
    80003c02:	6ce2                	ld	s9,24(sp)
    80003c04:	6d42                	ld	s10,16(sp)
    80003c06:	6da2                	ld	s11,8(sp)
    80003c08:	6165                	addi	sp,sp,112
    80003c0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c0c:	89da                	mv	s3,s6
    80003c0e:	bff1                	j	80003bea <readi+0xce>
    return 0;
    80003c10:	4501                	li	a0,0
}
    80003c12:	8082                	ret

0000000080003c14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c14:	457c                	lw	a5,76(a0)
    80003c16:	10d7e763          	bltu	a5,a3,80003d24 <writei+0x110>
{
    80003c1a:	7159                	addi	sp,sp,-112
    80003c1c:	f486                	sd	ra,104(sp)
    80003c1e:	f0a2                	sd	s0,96(sp)
    80003c20:	eca6                	sd	s1,88(sp)
    80003c22:	e8ca                	sd	s2,80(sp)
    80003c24:	e4ce                	sd	s3,72(sp)
    80003c26:	e0d2                	sd	s4,64(sp)
    80003c28:	fc56                	sd	s5,56(sp)
    80003c2a:	f85a                	sd	s6,48(sp)
    80003c2c:	f45e                	sd	s7,40(sp)
    80003c2e:	f062                	sd	s8,32(sp)
    80003c30:	ec66                	sd	s9,24(sp)
    80003c32:	e86a                	sd	s10,16(sp)
    80003c34:	e46e                	sd	s11,8(sp)
    80003c36:	1880                	addi	s0,sp,112
    80003c38:	8baa                	mv	s7,a0
    80003c3a:	8c2e                	mv	s8,a1
    80003c3c:	8ab2                	mv	s5,a2
    80003c3e:	8936                	mv	s2,a3
    80003c40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c42:	00e687bb          	addw	a5,a3,a4
    80003c46:	0ed7e163          	bltu	a5,a3,80003d28 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c4a:	00043737          	lui	a4,0x43
    80003c4e:	0cf76f63          	bltu	a4,a5,80003d2c <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c52:	0a0b0863          	beqz	s6,80003d02 <writei+0xee>
    80003c56:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c58:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c5c:	5cfd                	li	s9,-1
    80003c5e:	a091                	j	80003ca2 <writei+0x8e>
    80003c60:	02099d93          	slli	s11,s3,0x20
    80003c64:	020ddd93          	srli	s11,s11,0x20
    80003c68:	05848513          	addi	a0,s1,88
    80003c6c:	86ee                	mv	a3,s11
    80003c6e:	8656                	mv	a2,s5
    80003c70:	85e2                	mv	a1,s8
    80003c72:	953a                	add	a0,a0,a4
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	9cc080e7          	jalr	-1588(ra) # 80002640 <either_copyin>
    80003c7c:	07950263          	beq	a0,s9,80003ce0 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003c80:	8526                	mv	a0,s1
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	77c080e7          	jalr	1916(ra) # 800043fe <log_write>
    brelse(bp);
    80003c8a:	8526                	mv	a0,s1
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	50a080e7          	jalr	1290(ra) # 80003196 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c94:	01498a3b          	addw	s4,s3,s4
    80003c98:	0129893b          	addw	s2,s3,s2
    80003c9c:	9aee                	add	s5,s5,s11
    80003c9e:	056a7763          	bgeu	s4,s6,80003cec <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ca2:	000ba483          	lw	s1,0(s7)
    80003ca6:	00a9559b          	srliw	a1,s2,0xa
    80003caa:	855e                	mv	a0,s7
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	7ae080e7          	jalr	1966(ra) # 8000345a <bmap>
    80003cb4:	0005059b          	sext.w	a1,a0
    80003cb8:	8526                	mv	a0,s1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	3ac080e7          	jalr	940(ra) # 80003066 <bread>
    80003cc2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc4:	3ff97713          	andi	a4,s2,1023
    80003cc8:	40ed07bb          	subw	a5,s10,a4
    80003ccc:	414b06bb          	subw	a3,s6,s4
    80003cd0:	89be                	mv	s3,a5
    80003cd2:	2781                	sext.w	a5,a5
    80003cd4:	0006861b          	sext.w	a2,a3
    80003cd8:	f8f674e3          	bgeu	a2,a5,80003c60 <writei+0x4c>
    80003cdc:	89b6                	mv	s3,a3
    80003cde:	b749                	j	80003c60 <writei+0x4c>
      brelse(bp);
    80003ce0:	8526                	mv	a0,s1
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	4b4080e7          	jalr	1204(ra) # 80003196 <brelse>
      n = -1;
    80003cea:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003cec:	04cba783          	lw	a5,76(s7)
    80003cf0:	0127f463          	bgeu	a5,s2,80003cf8 <writei+0xe4>
      ip->size = off;
    80003cf4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cf8:	855e                	mv	a0,s7
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	aa4080e7          	jalr	-1372(ra) # 8000379e <iupdate>
  }

  return n;
    80003d02:	000b051b          	sext.w	a0,s6
}
    80003d06:	70a6                	ld	ra,104(sp)
    80003d08:	7406                	ld	s0,96(sp)
    80003d0a:	64e6                	ld	s1,88(sp)
    80003d0c:	6946                	ld	s2,80(sp)
    80003d0e:	69a6                	ld	s3,72(sp)
    80003d10:	6a06                	ld	s4,64(sp)
    80003d12:	7ae2                	ld	s5,56(sp)
    80003d14:	7b42                	ld	s6,48(sp)
    80003d16:	7ba2                	ld	s7,40(sp)
    80003d18:	7c02                	ld	s8,32(sp)
    80003d1a:	6ce2                	ld	s9,24(sp)
    80003d1c:	6d42                	ld	s10,16(sp)
    80003d1e:	6da2                	ld	s11,8(sp)
    80003d20:	6165                	addi	sp,sp,112
    80003d22:	8082                	ret
    return -1;
    80003d24:	557d                	li	a0,-1
}
    80003d26:	8082                	ret
    return -1;
    80003d28:	557d                	li	a0,-1
    80003d2a:	bff1                	j	80003d06 <writei+0xf2>
    return -1;
    80003d2c:	557d                	li	a0,-1
    80003d2e:	bfe1                	j	80003d06 <writei+0xf2>

0000000080003d30 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d30:	1141                	addi	sp,sp,-16
    80003d32:	e406                	sd	ra,8(sp)
    80003d34:	e022                	sd	s0,0(sp)
    80003d36:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d38:	4639                	li	a2,14
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	1f8080e7          	jalr	504(ra) # 80000f32 <strncmp>
}
    80003d42:	60a2                	ld	ra,8(sp)
    80003d44:	6402                	ld	s0,0(sp)
    80003d46:	0141                	addi	sp,sp,16
    80003d48:	8082                	ret

0000000080003d4a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d4a:	7139                	addi	sp,sp,-64
    80003d4c:	fc06                	sd	ra,56(sp)
    80003d4e:	f822                	sd	s0,48(sp)
    80003d50:	f426                	sd	s1,40(sp)
    80003d52:	f04a                	sd	s2,32(sp)
    80003d54:	ec4e                	sd	s3,24(sp)
    80003d56:	e852                	sd	s4,16(sp)
    80003d58:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d5a:	04451703          	lh	a4,68(a0)
    80003d5e:	4785                	li	a5,1
    80003d60:	00f71a63          	bne	a4,a5,80003d74 <dirlookup+0x2a>
    80003d64:	892a                	mv	s2,a0
    80003d66:	89ae                	mv	s3,a1
    80003d68:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6a:	457c                	lw	a5,76(a0)
    80003d6c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d6e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d70:	e79d                	bnez	a5,80003d9e <dirlookup+0x54>
    80003d72:	a8a5                	j	80003dea <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d74:	00005517          	auipc	a0,0x5
    80003d78:	8b450513          	addi	a0,a0,-1868 # 80008628 <syscalls+0x1a0>
    80003d7c:	ffffc097          	auipc	ra,0xffffc
    80003d80:	7cc080e7          	jalr	1996(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003d84:	00005517          	auipc	a0,0x5
    80003d88:	8bc50513          	addi	a0,a0,-1860 # 80008640 <syscalls+0x1b8>
    80003d8c:	ffffc097          	auipc	ra,0xffffc
    80003d90:	7bc080e7          	jalr	1980(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d94:	24c1                	addiw	s1,s1,16
    80003d96:	04c92783          	lw	a5,76(s2)
    80003d9a:	04f4f763          	bgeu	s1,a5,80003de8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d9e:	4741                	li	a4,16
    80003da0:	86a6                	mv	a3,s1
    80003da2:	fc040613          	addi	a2,s0,-64
    80003da6:	4581                	li	a1,0
    80003da8:	854a                	mv	a0,s2
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	d72080e7          	jalr	-654(ra) # 80003b1c <readi>
    80003db2:	47c1                	li	a5,16
    80003db4:	fcf518e3          	bne	a0,a5,80003d84 <dirlookup+0x3a>
    if(de.inum == 0)
    80003db8:	fc045783          	lhu	a5,-64(s0)
    80003dbc:	dfe1                	beqz	a5,80003d94 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dbe:	fc240593          	addi	a1,s0,-62
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	f6c080e7          	jalr	-148(ra) # 80003d30 <namecmp>
    80003dcc:	f561                	bnez	a0,80003d94 <dirlookup+0x4a>
      if(poff)
    80003dce:	000a0463          	beqz	s4,80003dd6 <dirlookup+0x8c>
        *poff = off;
    80003dd2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dd6:	fc045583          	lhu	a1,-64(s0)
    80003dda:	00092503          	lw	a0,0(s2)
    80003dde:	fffff097          	auipc	ra,0xfffff
    80003de2:	756080e7          	jalr	1878(ra) # 80003534 <iget>
    80003de6:	a011                	j	80003dea <dirlookup+0xa0>
  return 0;
    80003de8:	4501                	li	a0,0
}
    80003dea:	70e2                	ld	ra,56(sp)
    80003dec:	7442                	ld	s0,48(sp)
    80003dee:	74a2                	ld	s1,40(sp)
    80003df0:	7902                	ld	s2,32(sp)
    80003df2:	69e2                	ld	s3,24(sp)
    80003df4:	6a42                	ld	s4,16(sp)
    80003df6:	6121                	addi	sp,sp,64
    80003df8:	8082                	ret

0000000080003dfa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dfa:	711d                	addi	sp,sp,-96
    80003dfc:	ec86                	sd	ra,88(sp)
    80003dfe:	e8a2                	sd	s0,80(sp)
    80003e00:	e4a6                	sd	s1,72(sp)
    80003e02:	e0ca                	sd	s2,64(sp)
    80003e04:	fc4e                	sd	s3,56(sp)
    80003e06:	f852                	sd	s4,48(sp)
    80003e08:	f456                	sd	s5,40(sp)
    80003e0a:	f05a                	sd	s6,32(sp)
    80003e0c:	ec5e                	sd	s7,24(sp)
    80003e0e:	e862                	sd	s8,16(sp)
    80003e10:	e466                	sd	s9,8(sp)
    80003e12:	1080                	addi	s0,sp,96
    80003e14:	84aa                	mv	s1,a0
    80003e16:	8b2e                	mv	s6,a1
    80003e18:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e1a:	00054703          	lbu	a4,0(a0)
    80003e1e:	02f00793          	li	a5,47
    80003e22:	02f70363          	beq	a4,a5,80003e48 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e26:	ffffe097          	auipc	ra,0xffffe
    80003e2a:	d52080e7          	jalr	-686(ra) # 80001b78 <myproc>
    80003e2e:	15053503          	ld	a0,336(a0)
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	9f8080e7          	jalr	-1544(ra) # 8000382a <idup>
    80003e3a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e3c:	02f00913          	li	s2,47
  len = path - s;
    80003e40:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e42:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e44:	4c05                	li	s8,1
    80003e46:	a865                	j	80003efe <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e48:	4585                	li	a1,1
    80003e4a:	4505                	li	a0,1
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	6e8080e7          	jalr	1768(ra) # 80003534 <iget>
    80003e54:	89aa                	mv	s3,a0
    80003e56:	b7dd                	j	80003e3c <namex+0x42>
      iunlockput(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	c70080e7          	jalr	-912(ra) # 80003aca <iunlockput>
      return 0;
    80003e62:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e64:	854e                	mv	a0,s3
    80003e66:	60e6                	ld	ra,88(sp)
    80003e68:	6446                	ld	s0,80(sp)
    80003e6a:	64a6                	ld	s1,72(sp)
    80003e6c:	6906                	ld	s2,64(sp)
    80003e6e:	79e2                	ld	s3,56(sp)
    80003e70:	7a42                	ld	s4,48(sp)
    80003e72:	7aa2                	ld	s5,40(sp)
    80003e74:	7b02                	ld	s6,32(sp)
    80003e76:	6be2                	ld	s7,24(sp)
    80003e78:	6c42                	ld	s8,16(sp)
    80003e7a:	6ca2                	ld	s9,8(sp)
    80003e7c:	6125                	addi	sp,sp,96
    80003e7e:	8082                	ret
      iunlock(ip);
    80003e80:	854e                	mv	a0,s3
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	aa8080e7          	jalr	-1368(ra) # 8000392a <iunlock>
      return ip;
    80003e8a:	bfe9                	j	80003e64 <namex+0x6a>
      iunlockput(ip);
    80003e8c:	854e                	mv	a0,s3
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	c3c080e7          	jalr	-964(ra) # 80003aca <iunlockput>
      return 0;
    80003e96:	89d2                	mv	s3,s4
    80003e98:	b7f1                	j	80003e64 <namex+0x6a>
  len = path - s;
    80003e9a:	40b48633          	sub	a2,s1,a1
    80003e9e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ea2:	094cd463          	bge	s9,s4,80003f2a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ea6:	4639                	li	a2,14
    80003ea8:	8556                	mv	a0,s5
    80003eaa:	ffffd097          	auipc	ra,0xffffd
    80003eae:	00c080e7          	jalr	12(ra) # 80000eb6 <memmove>
  while(*path == '/')
    80003eb2:	0004c783          	lbu	a5,0(s1)
    80003eb6:	01279763          	bne	a5,s2,80003ec4 <namex+0xca>
    path++;
    80003eba:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	ff278de3          	beq	a5,s2,80003eba <namex+0xc0>
    ilock(ip);
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	9a2080e7          	jalr	-1630(ra) # 80003868 <ilock>
    if(ip->type != T_DIR){
    80003ece:	04499783          	lh	a5,68(s3)
    80003ed2:	f98793e3          	bne	a5,s8,80003e58 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ed6:	000b0563          	beqz	s6,80003ee0 <namex+0xe6>
    80003eda:	0004c783          	lbu	a5,0(s1)
    80003ede:	d3cd                	beqz	a5,80003e80 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ee0:	865e                	mv	a2,s7
    80003ee2:	85d6                	mv	a1,s5
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	e64080e7          	jalr	-412(ra) # 80003d4a <dirlookup>
    80003eee:	8a2a                	mv	s4,a0
    80003ef0:	dd51                	beqz	a0,80003e8c <namex+0x92>
    iunlockput(ip);
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	bd6080e7          	jalr	-1066(ra) # 80003aca <iunlockput>
    ip = next;
    80003efc:	89d2                	mv	s3,s4
  while(*path == '/')
    80003efe:	0004c783          	lbu	a5,0(s1)
    80003f02:	05279763          	bne	a5,s2,80003f50 <namex+0x156>
    path++;
    80003f06:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f08:	0004c783          	lbu	a5,0(s1)
    80003f0c:	ff278de3          	beq	a5,s2,80003f06 <namex+0x10c>
  if(*path == 0)
    80003f10:	c79d                	beqz	a5,80003f3e <namex+0x144>
    path++;
    80003f12:	85a6                	mv	a1,s1
  len = path - s;
    80003f14:	8a5e                	mv	s4,s7
    80003f16:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f18:	01278963          	beq	a5,s2,80003f2a <namex+0x130>
    80003f1c:	dfbd                	beqz	a5,80003e9a <namex+0xa0>
    path++;
    80003f1e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f20:	0004c783          	lbu	a5,0(s1)
    80003f24:	ff279ce3          	bne	a5,s2,80003f1c <namex+0x122>
    80003f28:	bf8d                	j	80003e9a <namex+0xa0>
    memmove(name, s, len);
    80003f2a:	2601                	sext.w	a2,a2
    80003f2c:	8556                	mv	a0,s5
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	f88080e7          	jalr	-120(ra) # 80000eb6 <memmove>
    name[len] = 0;
    80003f36:	9a56                	add	s4,s4,s5
    80003f38:	000a0023          	sb	zero,0(s4)
    80003f3c:	bf9d                	j	80003eb2 <namex+0xb8>
  if(nameiparent){
    80003f3e:	f20b03e3          	beqz	s6,80003e64 <namex+0x6a>
    iput(ip);
    80003f42:	854e                	mv	a0,s3
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	ade080e7          	jalr	-1314(ra) # 80003a22 <iput>
    return 0;
    80003f4c:	4981                	li	s3,0
    80003f4e:	bf19                	j	80003e64 <namex+0x6a>
  if(*path == 0)
    80003f50:	d7fd                	beqz	a5,80003f3e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f52:	0004c783          	lbu	a5,0(s1)
    80003f56:	85a6                	mv	a1,s1
    80003f58:	b7d1                	j	80003f1c <namex+0x122>

0000000080003f5a <dirlink>:
{
    80003f5a:	7139                	addi	sp,sp,-64
    80003f5c:	fc06                	sd	ra,56(sp)
    80003f5e:	f822                	sd	s0,48(sp)
    80003f60:	f426                	sd	s1,40(sp)
    80003f62:	f04a                	sd	s2,32(sp)
    80003f64:	ec4e                	sd	s3,24(sp)
    80003f66:	e852                	sd	s4,16(sp)
    80003f68:	0080                	addi	s0,sp,64
    80003f6a:	892a                	mv	s2,a0
    80003f6c:	8a2e                	mv	s4,a1
    80003f6e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f70:	4601                	li	a2,0
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	dd8080e7          	jalr	-552(ra) # 80003d4a <dirlookup>
    80003f7a:	e93d                	bnez	a0,80003ff0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7c:	04c92483          	lw	s1,76(s2)
    80003f80:	c49d                	beqz	s1,80003fae <dirlink+0x54>
    80003f82:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f84:	4741                	li	a4,16
    80003f86:	86a6                	mv	a3,s1
    80003f88:	fc040613          	addi	a2,s0,-64
    80003f8c:	4581                	li	a1,0
    80003f8e:	854a                	mv	a0,s2
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	b8c080e7          	jalr	-1140(ra) # 80003b1c <readi>
    80003f98:	47c1                	li	a5,16
    80003f9a:	06f51163          	bne	a0,a5,80003ffc <dirlink+0xa2>
    if(de.inum == 0)
    80003f9e:	fc045783          	lhu	a5,-64(s0)
    80003fa2:	c791                	beqz	a5,80003fae <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fa4:	24c1                	addiw	s1,s1,16
    80003fa6:	04c92783          	lw	a5,76(s2)
    80003faa:	fcf4ede3          	bltu	s1,a5,80003f84 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fae:	4639                	li	a2,14
    80003fb0:	85d2                	mv	a1,s4
    80003fb2:	fc240513          	addi	a0,s0,-62
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	fb8080e7          	jalr	-72(ra) # 80000f6e <strncpy>
  de.inum = inum;
    80003fbe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc2:	4741                	li	a4,16
    80003fc4:	86a6                	mv	a3,s1
    80003fc6:	fc040613          	addi	a2,s0,-64
    80003fca:	4581                	li	a1,0
    80003fcc:	854a                	mv	a0,s2
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	c46080e7          	jalr	-954(ra) # 80003c14 <writei>
    80003fd6:	872a                	mv	a4,a0
    80003fd8:	47c1                	li	a5,16
  return 0;
    80003fda:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fdc:	02f71863          	bne	a4,a5,8000400c <dirlink+0xb2>
}
    80003fe0:	70e2                	ld	ra,56(sp)
    80003fe2:	7442                	ld	s0,48(sp)
    80003fe4:	74a2                	ld	s1,40(sp)
    80003fe6:	7902                	ld	s2,32(sp)
    80003fe8:	69e2                	ld	s3,24(sp)
    80003fea:	6a42                	ld	s4,16(sp)
    80003fec:	6121                	addi	sp,sp,64
    80003fee:	8082                	ret
    iput(ip);
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	a32080e7          	jalr	-1486(ra) # 80003a22 <iput>
    return -1;
    80003ff8:	557d                	li	a0,-1
    80003ffa:	b7dd                	j	80003fe0 <dirlink+0x86>
      panic("dirlink read");
    80003ffc:	00004517          	auipc	a0,0x4
    80004000:	65450513          	addi	a0,a0,1620 # 80008650 <syscalls+0x1c8>
    80004004:	ffffc097          	auipc	ra,0xffffc
    80004008:	544080e7          	jalr	1348(ra) # 80000548 <panic>
    panic("dirlink");
    8000400c:	00004517          	auipc	a0,0x4
    80004010:	76450513          	addi	a0,a0,1892 # 80008770 <syscalls+0x2e8>
    80004014:	ffffc097          	auipc	ra,0xffffc
    80004018:	534080e7          	jalr	1332(ra) # 80000548 <panic>

000000008000401c <namei>:

struct inode*
namei(char *path)
{
    8000401c:	1101                	addi	sp,sp,-32
    8000401e:	ec06                	sd	ra,24(sp)
    80004020:	e822                	sd	s0,16(sp)
    80004022:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004024:	fe040613          	addi	a2,s0,-32
    80004028:	4581                	li	a1,0
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	dd0080e7          	jalr	-560(ra) # 80003dfa <namex>
}
    80004032:	60e2                	ld	ra,24(sp)
    80004034:	6442                	ld	s0,16(sp)
    80004036:	6105                	addi	sp,sp,32
    80004038:	8082                	ret

000000008000403a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000403a:	1141                	addi	sp,sp,-16
    8000403c:	e406                	sd	ra,8(sp)
    8000403e:	e022                	sd	s0,0(sp)
    80004040:	0800                	addi	s0,sp,16
    80004042:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004044:	4585                	li	a1,1
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	db4080e7          	jalr	-588(ra) # 80003dfa <namex>
}
    8000404e:	60a2                	ld	ra,8(sp)
    80004050:	6402                	ld	s0,0(sp)
    80004052:	0141                	addi	sp,sp,16
    80004054:	8082                	ret

0000000080004056 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004056:	1101                	addi	sp,sp,-32
    80004058:	ec06                	sd	ra,24(sp)
    8000405a:	e822                	sd	s0,16(sp)
    8000405c:	e426                	sd	s1,8(sp)
    8000405e:	e04a                	sd	s2,0(sp)
    80004060:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004062:	0023e917          	auipc	s2,0x23e
    80004066:	8a690913          	addi	s2,s2,-1882 # 80241908 <log>
    8000406a:	01892583          	lw	a1,24(s2)
    8000406e:	02892503          	lw	a0,40(s2)
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	ff4080e7          	jalr	-12(ra) # 80003066 <bread>
    8000407a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000407c:	02c92683          	lw	a3,44(s2)
    80004080:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004082:	02d05763          	blez	a3,800040b0 <write_head+0x5a>
    80004086:	0023e797          	auipc	a5,0x23e
    8000408a:	8b278793          	addi	a5,a5,-1870 # 80241938 <log+0x30>
    8000408e:	05c50713          	addi	a4,a0,92
    80004092:	36fd                	addiw	a3,a3,-1
    80004094:	1682                	slli	a3,a3,0x20
    80004096:	9281                	srli	a3,a3,0x20
    80004098:	068a                	slli	a3,a3,0x2
    8000409a:	0023e617          	auipc	a2,0x23e
    8000409e:	8a260613          	addi	a2,a2,-1886 # 8024193c <log+0x34>
    800040a2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040a4:	4390                	lw	a2,0(a5)
    800040a6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040a8:	0791                	addi	a5,a5,4
    800040aa:	0711                	addi	a4,a4,4
    800040ac:	fed79ce3          	bne	a5,a3,800040a4 <write_head+0x4e>
  }
  bwrite(buf);
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	0a6080e7          	jalr	166(ra) # 80003158 <bwrite>
  brelse(buf);
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	0da080e7          	jalr	218(ra) # 80003196 <brelse>
}
    800040c4:	60e2                	ld	ra,24(sp)
    800040c6:	6442                	ld	s0,16(sp)
    800040c8:	64a2                	ld	s1,8(sp)
    800040ca:	6902                	ld	s2,0(sp)
    800040cc:	6105                	addi	sp,sp,32
    800040ce:	8082                	ret

00000000800040d0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d0:	0023e797          	auipc	a5,0x23e
    800040d4:	8647a783          	lw	a5,-1948(a5) # 80241934 <log+0x2c>
    800040d8:	0af05663          	blez	a5,80004184 <install_trans+0xb4>
{
    800040dc:	7139                	addi	sp,sp,-64
    800040de:	fc06                	sd	ra,56(sp)
    800040e0:	f822                	sd	s0,48(sp)
    800040e2:	f426                	sd	s1,40(sp)
    800040e4:	f04a                	sd	s2,32(sp)
    800040e6:	ec4e                	sd	s3,24(sp)
    800040e8:	e852                	sd	s4,16(sp)
    800040ea:	e456                	sd	s5,8(sp)
    800040ec:	0080                	addi	s0,sp,64
    800040ee:	0023ea97          	auipc	s5,0x23e
    800040f2:	84aa8a93          	addi	s5,s5,-1974 # 80241938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f8:	0023e997          	auipc	s3,0x23e
    800040fc:	81098993          	addi	s3,s3,-2032 # 80241908 <log>
    80004100:	0189a583          	lw	a1,24(s3)
    80004104:	014585bb          	addw	a1,a1,s4
    80004108:	2585                	addiw	a1,a1,1
    8000410a:	0289a503          	lw	a0,40(s3)
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	f58080e7          	jalr	-168(ra) # 80003066 <bread>
    80004116:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004118:	000aa583          	lw	a1,0(s5)
    8000411c:	0289a503          	lw	a0,40(s3)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	f46080e7          	jalr	-186(ra) # 80003066 <bread>
    80004128:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000412a:	40000613          	li	a2,1024
    8000412e:	05890593          	addi	a1,s2,88
    80004132:	05850513          	addi	a0,a0,88
    80004136:	ffffd097          	auipc	ra,0xffffd
    8000413a:	d80080e7          	jalr	-640(ra) # 80000eb6 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	018080e7          	jalr	24(ra) # 80003158 <bwrite>
    bunpin(dbuf);
    80004148:	8526                	mv	a0,s1
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	126080e7          	jalr	294(ra) # 80003270 <bunpin>
    brelse(lbuf);
    80004152:	854a                	mv	a0,s2
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	042080e7          	jalr	66(ra) # 80003196 <brelse>
    brelse(dbuf);
    8000415c:	8526                	mv	a0,s1
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	038080e7          	jalr	56(ra) # 80003196 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004166:	2a05                	addiw	s4,s4,1
    80004168:	0a91                	addi	s5,s5,4
    8000416a:	02c9a783          	lw	a5,44(s3)
    8000416e:	f8fa49e3          	blt	s4,a5,80004100 <install_trans+0x30>
}
    80004172:	70e2                	ld	ra,56(sp)
    80004174:	7442                	ld	s0,48(sp)
    80004176:	74a2                	ld	s1,40(sp)
    80004178:	7902                	ld	s2,32(sp)
    8000417a:	69e2                	ld	s3,24(sp)
    8000417c:	6a42                	ld	s4,16(sp)
    8000417e:	6aa2                	ld	s5,8(sp)
    80004180:	6121                	addi	sp,sp,64
    80004182:	8082                	ret
    80004184:	8082                	ret

0000000080004186 <initlog>:
{
    80004186:	7179                	addi	sp,sp,-48
    80004188:	f406                	sd	ra,40(sp)
    8000418a:	f022                	sd	s0,32(sp)
    8000418c:	ec26                	sd	s1,24(sp)
    8000418e:	e84a                	sd	s2,16(sp)
    80004190:	e44e                	sd	s3,8(sp)
    80004192:	1800                	addi	s0,sp,48
    80004194:	892a                	mv	s2,a0
    80004196:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004198:	0023d497          	auipc	s1,0x23d
    8000419c:	77048493          	addi	s1,s1,1904 # 80241908 <log>
    800041a0:	00004597          	auipc	a1,0x4
    800041a4:	4c058593          	addi	a1,a1,1216 # 80008660 <syscalls+0x1d8>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	b20080e7          	jalr	-1248(ra) # 80000cca <initlock>
  log.start = sb->logstart;
    800041b2:	0149a583          	lw	a1,20(s3)
    800041b6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041b8:	0109a783          	lw	a5,16(s3)
    800041bc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041be:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041c2:	854a                	mv	a0,s2
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	ea2080e7          	jalr	-350(ra) # 80003066 <bread>
  log.lh.n = lh->n;
    800041cc:	4d3c                	lw	a5,88(a0)
    800041ce:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041d0:	02f05563          	blez	a5,800041fa <initlog+0x74>
    800041d4:	05c50713          	addi	a4,a0,92
    800041d8:	0023d697          	auipc	a3,0x23d
    800041dc:	76068693          	addi	a3,a3,1888 # 80241938 <log+0x30>
    800041e0:	37fd                	addiw	a5,a5,-1
    800041e2:	1782                	slli	a5,a5,0x20
    800041e4:	9381                	srli	a5,a5,0x20
    800041e6:	078a                	slli	a5,a5,0x2
    800041e8:	06050613          	addi	a2,a0,96
    800041ec:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041ee:	4310                	lw	a2,0(a4)
    800041f0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041f2:	0711                	addi	a4,a4,4
    800041f4:	0691                	addi	a3,a3,4
    800041f6:	fef71ce3          	bne	a4,a5,800041ee <initlog+0x68>
  brelse(buf);
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	f9c080e7          	jalr	-100(ra) # 80003196 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004202:	00000097          	auipc	ra,0x0
    80004206:	ece080e7          	jalr	-306(ra) # 800040d0 <install_trans>
  log.lh.n = 0;
    8000420a:	0023d797          	auipc	a5,0x23d
    8000420e:	7207a523          	sw	zero,1834(a5) # 80241934 <log+0x2c>
  write_head(); // clear the log
    80004212:	00000097          	auipc	ra,0x0
    80004216:	e44080e7          	jalr	-444(ra) # 80004056 <write_head>
}
    8000421a:	70a2                	ld	ra,40(sp)
    8000421c:	7402                	ld	s0,32(sp)
    8000421e:	64e2                	ld	s1,24(sp)
    80004220:	6942                	ld	s2,16(sp)
    80004222:	69a2                	ld	s3,8(sp)
    80004224:	6145                	addi	sp,sp,48
    80004226:	8082                	ret

0000000080004228 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004228:	1101                	addi	sp,sp,-32
    8000422a:	ec06                	sd	ra,24(sp)
    8000422c:	e822                	sd	s0,16(sp)
    8000422e:	e426                	sd	s1,8(sp)
    80004230:	e04a                	sd	s2,0(sp)
    80004232:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004234:	0023d517          	auipc	a0,0x23d
    80004238:	6d450513          	addi	a0,a0,1748 # 80241908 <log>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	b1e080e7          	jalr	-1250(ra) # 80000d5a <acquire>
  while(1){
    if(log.committing){
    80004244:	0023d497          	auipc	s1,0x23d
    80004248:	6c448493          	addi	s1,s1,1732 # 80241908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424c:	4979                	li	s2,30
    8000424e:	a039                	j	8000425c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004250:	85a6                	mv	a1,s1
    80004252:	8526                	mv	a0,s1
    80004254:	ffffe097          	auipc	ra,0xffffe
    80004258:	134080e7          	jalr	308(ra) # 80002388 <sleep>
    if(log.committing){
    8000425c:	50dc                	lw	a5,36(s1)
    8000425e:	fbed                	bnez	a5,80004250 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004260:	509c                	lw	a5,32(s1)
    80004262:	0017871b          	addiw	a4,a5,1
    80004266:	0007069b          	sext.w	a3,a4
    8000426a:	0027179b          	slliw	a5,a4,0x2
    8000426e:	9fb9                	addw	a5,a5,a4
    80004270:	0017979b          	slliw	a5,a5,0x1
    80004274:	54d8                	lw	a4,44(s1)
    80004276:	9fb9                	addw	a5,a5,a4
    80004278:	00f95963          	bge	s2,a5,8000428a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000427c:	85a6                	mv	a1,s1
    8000427e:	8526                	mv	a0,s1
    80004280:	ffffe097          	auipc	ra,0xffffe
    80004284:	108080e7          	jalr	264(ra) # 80002388 <sleep>
    80004288:	bfd1                	j	8000425c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000428a:	0023d517          	auipc	a0,0x23d
    8000428e:	67e50513          	addi	a0,a0,1662 # 80241908 <log>
    80004292:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	b7a080e7          	jalr	-1158(ra) # 80000e0e <release>
      break;
    }
  }
}
    8000429c:	60e2                	ld	ra,24(sp)
    8000429e:	6442                	ld	s0,16(sp)
    800042a0:	64a2                	ld	s1,8(sp)
    800042a2:	6902                	ld	s2,0(sp)
    800042a4:	6105                	addi	sp,sp,32
    800042a6:	8082                	ret

00000000800042a8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042a8:	7139                	addi	sp,sp,-64
    800042aa:	fc06                	sd	ra,56(sp)
    800042ac:	f822                	sd	s0,48(sp)
    800042ae:	f426                	sd	s1,40(sp)
    800042b0:	f04a                	sd	s2,32(sp)
    800042b2:	ec4e                	sd	s3,24(sp)
    800042b4:	e852                	sd	s4,16(sp)
    800042b6:	e456                	sd	s5,8(sp)
    800042b8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ba:	0023d497          	auipc	s1,0x23d
    800042be:	64e48493          	addi	s1,s1,1614 # 80241908 <log>
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a96080e7          	jalr	-1386(ra) # 80000d5a <acquire>
  log.outstanding -= 1;
    800042cc:	509c                	lw	a5,32(s1)
    800042ce:	37fd                	addiw	a5,a5,-1
    800042d0:	0007891b          	sext.w	s2,a5
    800042d4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042d6:	50dc                	lw	a5,36(s1)
    800042d8:	efb9                	bnez	a5,80004336 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042da:	06091663          	bnez	s2,80004346 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042de:	0023d497          	auipc	s1,0x23d
    800042e2:	62a48493          	addi	s1,s1,1578 # 80241908 <log>
    800042e6:	4785                	li	a5,1
    800042e8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	b22080e7          	jalr	-1246(ra) # 80000e0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042f4:	54dc                	lw	a5,44(s1)
    800042f6:	06f04763          	bgtz	a5,80004364 <end_op+0xbc>
    acquire(&log.lock);
    800042fa:	0023d497          	auipc	s1,0x23d
    800042fe:	60e48493          	addi	s1,s1,1550 # 80241908 <log>
    80004302:	8526                	mv	a0,s1
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	a56080e7          	jalr	-1450(ra) # 80000d5a <acquire>
    log.committing = 0;
    8000430c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004310:	8526                	mv	a0,s1
    80004312:	ffffe097          	auipc	ra,0xffffe
    80004316:	1fc080e7          	jalr	508(ra) # 8000250e <wakeup>
    release(&log.lock);
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	af2080e7          	jalr	-1294(ra) # 80000e0e <release>
}
    80004324:	70e2                	ld	ra,56(sp)
    80004326:	7442                	ld	s0,48(sp)
    80004328:	74a2                	ld	s1,40(sp)
    8000432a:	7902                	ld	s2,32(sp)
    8000432c:	69e2                	ld	s3,24(sp)
    8000432e:	6a42                	ld	s4,16(sp)
    80004330:	6aa2                	ld	s5,8(sp)
    80004332:	6121                	addi	sp,sp,64
    80004334:	8082                	ret
    panic("log.committing");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	33250513          	addi	a0,a0,818 # 80008668 <syscalls+0x1e0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	20a080e7          	jalr	522(ra) # 80000548 <panic>
    wakeup(&log);
    80004346:	0023d497          	auipc	s1,0x23d
    8000434a:	5c248493          	addi	s1,s1,1474 # 80241908 <log>
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	1be080e7          	jalr	446(ra) # 8000250e <wakeup>
  release(&log.lock);
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	ab4080e7          	jalr	-1356(ra) # 80000e0e <release>
  if(do_commit){
    80004362:	b7c9                	j	80004324 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004364:	0023da97          	auipc	s5,0x23d
    80004368:	5d4a8a93          	addi	s5,s5,1492 # 80241938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000436c:	0023da17          	auipc	s4,0x23d
    80004370:	59ca0a13          	addi	s4,s4,1436 # 80241908 <log>
    80004374:	018a2583          	lw	a1,24(s4)
    80004378:	012585bb          	addw	a1,a1,s2
    8000437c:	2585                	addiw	a1,a1,1
    8000437e:	028a2503          	lw	a0,40(s4)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	ce4080e7          	jalr	-796(ra) # 80003066 <bread>
    8000438a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000438c:	000aa583          	lw	a1,0(s5)
    80004390:	028a2503          	lw	a0,40(s4)
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	cd2080e7          	jalr	-814(ra) # 80003066 <bread>
    8000439c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000439e:	40000613          	li	a2,1024
    800043a2:	05850593          	addi	a1,a0,88
    800043a6:	05848513          	addi	a0,s1,88
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	b0c080e7          	jalr	-1268(ra) # 80000eb6 <memmove>
    bwrite(to);  // write the log
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	da4080e7          	jalr	-604(ra) # 80003158 <bwrite>
    brelse(from);
    800043bc:	854e                	mv	a0,s3
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	dd8080e7          	jalr	-552(ra) # 80003196 <brelse>
    brelse(to);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	dce080e7          	jalr	-562(ra) # 80003196 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	2905                	addiw	s2,s2,1
    800043d2:	0a91                	addi	s5,s5,4
    800043d4:	02ca2783          	lw	a5,44(s4)
    800043d8:	f8f94ee3          	blt	s2,a5,80004374 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	c7a080e7          	jalr	-902(ra) # 80004056 <write_head>
    install_trans(); // Now install writes to home locations
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	cec080e7          	jalr	-788(ra) # 800040d0 <install_trans>
    log.lh.n = 0;
    800043ec:	0023d797          	auipc	a5,0x23d
    800043f0:	5407a423          	sw	zero,1352(a5) # 80241934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	c62080e7          	jalr	-926(ra) # 80004056 <write_head>
    800043fc:	bdfd                	j	800042fa <end_op+0x52>

00000000800043fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043fe:	1101                	addi	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	e04a                	sd	s2,0(sp)
    80004408:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440a:	0023d717          	auipc	a4,0x23d
    8000440e:	52a72703          	lw	a4,1322(a4) # 80241934 <log+0x2c>
    80004412:	47f5                	li	a5,29
    80004414:	08e7c063          	blt	a5,a4,80004494 <log_write+0x96>
    80004418:	84aa                	mv	s1,a0
    8000441a:	0023d797          	auipc	a5,0x23d
    8000441e:	50a7a783          	lw	a5,1290(a5) # 80241924 <log+0x1c>
    80004422:	37fd                	addiw	a5,a5,-1
    80004424:	06f75863          	bge	a4,a5,80004494 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004428:	0023d797          	auipc	a5,0x23d
    8000442c:	5007a783          	lw	a5,1280(a5) # 80241928 <log+0x20>
    80004430:	06f05a63          	blez	a5,800044a4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004434:	0023d917          	auipc	s2,0x23d
    80004438:	4d490913          	addi	s2,s2,1236 # 80241908 <log>
    8000443c:	854a                	mv	a0,s2
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	91c080e7          	jalr	-1764(ra) # 80000d5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004446:	02c92603          	lw	a2,44(s2)
    8000444a:	06c05563          	blez	a2,800044b4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000444e:	44cc                	lw	a1,12(s1)
    80004450:	0023d717          	auipc	a4,0x23d
    80004454:	4e870713          	addi	a4,a4,1256 # 80241938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004458:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000445a:	4314                	lw	a3,0(a4)
    8000445c:	04b68d63          	beq	a3,a1,800044b6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004460:	2785                	addiw	a5,a5,1
    80004462:	0711                	addi	a4,a4,4
    80004464:	fec79be3          	bne	a5,a2,8000445a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004468:	0621                	addi	a2,a2,8
    8000446a:	060a                	slli	a2,a2,0x2
    8000446c:	0023d797          	auipc	a5,0x23d
    80004470:	49c78793          	addi	a5,a5,1180 # 80241908 <log>
    80004474:	963e                	add	a2,a2,a5
    80004476:	44dc                	lw	a5,12(s1)
    80004478:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000447a:	8526                	mv	a0,s1
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	db8080e7          	jalr	-584(ra) # 80003234 <bpin>
    log.lh.n++;
    80004484:	0023d717          	auipc	a4,0x23d
    80004488:	48470713          	addi	a4,a4,1156 # 80241908 <log>
    8000448c:	575c                	lw	a5,44(a4)
    8000448e:	2785                	addiw	a5,a5,1
    80004490:	d75c                	sw	a5,44(a4)
    80004492:	a83d                	j	800044d0 <log_write+0xd2>
    panic("too big a transaction");
    80004494:	00004517          	auipc	a0,0x4
    80004498:	1e450513          	addi	a0,a0,484 # 80008678 <syscalls+0x1f0>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	0ac080e7          	jalr	172(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800044a4:	00004517          	auipc	a0,0x4
    800044a8:	1ec50513          	addi	a0,a0,492 # 80008690 <syscalls+0x208>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	09c080e7          	jalr	156(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044b4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044b6:	00878713          	addi	a4,a5,8
    800044ba:	00271693          	slli	a3,a4,0x2
    800044be:	0023d717          	auipc	a4,0x23d
    800044c2:	44a70713          	addi	a4,a4,1098 # 80241908 <log>
    800044c6:	9736                	add	a4,a4,a3
    800044c8:	44d4                	lw	a3,12(s1)
    800044ca:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044cc:	faf607e3          	beq	a2,a5,8000447a <log_write+0x7c>
  }
  release(&log.lock);
    800044d0:	0023d517          	auipc	a0,0x23d
    800044d4:	43850513          	addi	a0,a0,1080 # 80241908 <log>
    800044d8:	ffffd097          	auipc	ra,0xffffd
    800044dc:	936080e7          	jalr	-1738(ra) # 80000e0e <release>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6902                	ld	s2,0(sp)
    800044e8:	6105                	addi	sp,sp,32
    800044ea:	8082                	ret

00000000800044ec <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	e04a                	sd	s2,0(sp)
    800044f6:	1000                	addi	s0,sp,32
    800044f8:	84aa                	mv	s1,a0
    800044fa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044fc:	00004597          	auipc	a1,0x4
    80004500:	1b458593          	addi	a1,a1,436 # 800086b0 <syscalls+0x228>
    80004504:	0521                	addi	a0,a0,8
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	7c4080e7          	jalr	1988(ra) # 80000cca <initlock>
  lk->name = name;
    8000450e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004512:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004516:	0204a423          	sw	zero,40(s1)
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	64a2                	ld	s1,8(sp)
    80004520:	6902                	ld	s2,0(sp)
    80004522:	6105                	addi	sp,sp,32
    80004524:	8082                	ret

0000000080004526 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004526:	1101                	addi	sp,sp,-32
    80004528:	ec06                	sd	ra,24(sp)
    8000452a:	e822                	sd	s0,16(sp)
    8000452c:	e426                	sd	s1,8(sp)
    8000452e:	e04a                	sd	s2,0(sp)
    80004530:	1000                	addi	s0,sp,32
    80004532:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004534:	00850913          	addi	s2,a0,8
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	820080e7          	jalr	-2016(ra) # 80000d5a <acquire>
  while (lk->locked) {
    80004542:	409c                	lw	a5,0(s1)
    80004544:	cb89                	beqz	a5,80004556 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004546:	85ca                	mv	a1,s2
    80004548:	8526                	mv	a0,s1
    8000454a:	ffffe097          	auipc	ra,0xffffe
    8000454e:	e3e080e7          	jalr	-450(ra) # 80002388 <sleep>
  while (lk->locked) {
    80004552:	409c                	lw	a5,0(s1)
    80004554:	fbed                	bnez	a5,80004546 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004556:	4785                	li	a5,1
    80004558:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000455a:	ffffd097          	auipc	ra,0xffffd
    8000455e:	61e080e7          	jalr	1566(ra) # 80001b78 <myproc>
    80004562:	5d1c                	lw	a5,56(a0)
    80004564:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004566:	854a                	mv	a0,s2
    80004568:	ffffd097          	auipc	ra,0xffffd
    8000456c:	8a6080e7          	jalr	-1882(ra) # 80000e0e <release>
}
    80004570:	60e2                	ld	ra,24(sp)
    80004572:	6442                	ld	s0,16(sp)
    80004574:	64a2                	ld	s1,8(sp)
    80004576:	6902                	ld	s2,0(sp)
    80004578:	6105                	addi	sp,sp,32
    8000457a:	8082                	ret

000000008000457c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000457c:	1101                	addi	sp,sp,-32
    8000457e:	ec06                	sd	ra,24(sp)
    80004580:	e822                	sd	s0,16(sp)
    80004582:	e426                	sd	s1,8(sp)
    80004584:	e04a                	sd	s2,0(sp)
    80004586:	1000                	addi	s0,sp,32
    80004588:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000458a:	00850913          	addi	s2,a0,8
    8000458e:	854a                	mv	a0,s2
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	7ca080e7          	jalr	1994(ra) # 80000d5a <acquire>
  lk->locked = 0;
    80004598:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000459c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	f6c080e7          	jalr	-148(ra) # 8000250e <wakeup>
  release(&lk->lk);
    800045aa:	854a                	mv	a0,s2
    800045ac:	ffffd097          	auipc	ra,0xffffd
    800045b0:	862080e7          	jalr	-1950(ra) # 80000e0e <release>
}
    800045b4:	60e2                	ld	ra,24(sp)
    800045b6:	6442                	ld	s0,16(sp)
    800045b8:	64a2                	ld	s1,8(sp)
    800045ba:	6902                	ld	s2,0(sp)
    800045bc:	6105                	addi	sp,sp,32
    800045be:	8082                	ret

00000000800045c0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045c0:	7179                	addi	sp,sp,-48
    800045c2:	f406                	sd	ra,40(sp)
    800045c4:	f022                	sd	s0,32(sp)
    800045c6:	ec26                	sd	s1,24(sp)
    800045c8:	e84a                	sd	s2,16(sp)
    800045ca:	e44e                	sd	s3,8(sp)
    800045cc:	1800                	addi	s0,sp,48
    800045ce:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045d0:	00850913          	addi	s2,a0,8
    800045d4:	854a                	mv	a0,s2
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	784080e7          	jalr	1924(ra) # 80000d5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045de:	409c                	lw	a5,0(s1)
    800045e0:	ef99                	bnez	a5,800045fe <holdingsleep+0x3e>
    800045e2:	4481                	li	s1,0
  release(&lk->lk);
    800045e4:	854a                	mv	a0,s2
    800045e6:	ffffd097          	auipc	ra,0xffffd
    800045ea:	828080e7          	jalr	-2008(ra) # 80000e0e <release>
  return r;
}
    800045ee:	8526                	mv	a0,s1
    800045f0:	70a2                	ld	ra,40(sp)
    800045f2:	7402                	ld	s0,32(sp)
    800045f4:	64e2                	ld	s1,24(sp)
    800045f6:	6942                	ld	s2,16(sp)
    800045f8:	69a2                	ld	s3,8(sp)
    800045fa:	6145                	addi	sp,sp,48
    800045fc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045fe:	0284a983          	lw	s3,40(s1)
    80004602:	ffffd097          	auipc	ra,0xffffd
    80004606:	576080e7          	jalr	1398(ra) # 80001b78 <myproc>
    8000460a:	5d04                	lw	s1,56(a0)
    8000460c:	413484b3          	sub	s1,s1,s3
    80004610:	0014b493          	seqz	s1,s1
    80004614:	bfc1                	j	800045e4 <holdingsleep+0x24>

0000000080004616 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004616:	1141                	addi	sp,sp,-16
    80004618:	e406                	sd	ra,8(sp)
    8000461a:	e022                	sd	s0,0(sp)
    8000461c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000461e:	00004597          	auipc	a1,0x4
    80004622:	0a258593          	addi	a1,a1,162 # 800086c0 <syscalls+0x238>
    80004626:	0023d517          	auipc	a0,0x23d
    8000462a:	42a50513          	addi	a0,a0,1066 # 80241a50 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	69c080e7          	jalr	1692(ra) # 80000cca <initlock>
}
    80004636:	60a2                	ld	ra,8(sp)
    80004638:	6402                	ld	s0,0(sp)
    8000463a:	0141                	addi	sp,sp,16
    8000463c:	8082                	ret

000000008000463e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004648:	0023d517          	auipc	a0,0x23d
    8000464c:	40850513          	addi	a0,a0,1032 # 80241a50 <ftable>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	70a080e7          	jalr	1802(ra) # 80000d5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004658:	0023d497          	auipc	s1,0x23d
    8000465c:	41048493          	addi	s1,s1,1040 # 80241a68 <ftable+0x18>
    80004660:	0023e717          	auipc	a4,0x23e
    80004664:	3a870713          	addi	a4,a4,936 # 80242a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004668:	40dc                	lw	a5,4(s1)
    8000466a:	cf99                	beqz	a5,80004688 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000466c:	02848493          	addi	s1,s1,40
    80004670:	fee49ce3          	bne	s1,a4,80004668 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004674:	0023d517          	auipc	a0,0x23d
    80004678:	3dc50513          	addi	a0,a0,988 # 80241a50 <ftable>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	792080e7          	jalr	1938(ra) # 80000e0e <release>
  return 0;
    80004684:	4481                	li	s1,0
    80004686:	a819                	j	8000469c <filealloc+0x5e>
      f->ref = 1;
    80004688:	4785                	li	a5,1
    8000468a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000468c:	0023d517          	auipc	a0,0x23d
    80004690:	3c450513          	addi	a0,a0,964 # 80241a50 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	77a080e7          	jalr	1914(ra) # 80000e0e <release>
}
    8000469c:	8526                	mv	a0,s1
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret

00000000800046a8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046a8:	1101                	addi	sp,sp,-32
    800046aa:	ec06                	sd	ra,24(sp)
    800046ac:	e822                	sd	s0,16(sp)
    800046ae:	e426                	sd	s1,8(sp)
    800046b0:	1000                	addi	s0,sp,32
    800046b2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046b4:	0023d517          	auipc	a0,0x23d
    800046b8:	39c50513          	addi	a0,a0,924 # 80241a50 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	69e080e7          	jalr	1694(ra) # 80000d5a <acquire>
  if(f->ref < 1)
    800046c4:	40dc                	lw	a5,4(s1)
    800046c6:	02f05263          	blez	a5,800046ea <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046ca:	2785                	addiw	a5,a5,1
    800046cc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046ce:	0023d517          	auipc	a0,0x23d
    800046d2:	38250513          	addi	a0,a0,898 # 80241a50 <ftable>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	738080e7          	jalr	1848(ra) # 80000e0e <release>
  return f;
}
    800046de:	8526                	mv	a0,s1
    800046e0:	60e2                	ld	ra,24(sp)
    800046e2:	6442                	ld	s0,16(sp)
    800046e4:	64a2                	ld	s1,8(sp)
    800046e6:	6105                	addi	sp,sp,32
    800046e8:	8082                	ret
    panic("filedup");
    800046ea:	00004517          	auipc	a0,0x4
    800046ee:	fde50513          	addi	a0,a0,-34 # 800086c8 <syscalls+0x240>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	e56080e7          	jalr	-426(ra) # 80000548 <panic>

00000000800046fa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046fa:	7139                	addi	sp,sp,-64
    800046fc:	fc06                	sd	ra,56(sp)
    800046fe:	f822                	sd	s0,48(sp)
    80004700:	f426                	sd	s1,40(sp)
    80004702:	f04a                	sd	s2,32(sp)
    80004704:	ec4e                	sd	s3,24(sp)
    80004706:	e852                	sd	s4,16(sp)
    80004708:	e456                	sd	s5,8(sp)
    8000470a:	0080                	addi	s0,sp,64
    8000470c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000470e:	0023d517          	auipc	a0,0x23d
    80004712:	34250513          	addi	a0,a0,834 # 80241a50 <ftable>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	644080e7          	jalr	1604(ra) # 80000d5a <acquire>
  if(f->ref < 1)
    8000471e:	40dc                	lw	a5,4(s1)
    80004720:	06f05163          	blez	a5,80004782 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004724:	37fd                	addiw	a5,a5,-1
    80004726:	0007871b          	sext.w	a4,a5
    8000472a:	c0dc                	sw	a5,4(s1)
    8000472c:	06e04363          	bgtz	a4,80004792 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004730:	0004a903          	lw	s2,0(s1)
    80004734:	0094ca83          	lbu	s5,9(s1)
    80004738:	0104ba03          	ld	s4,16(s1)
    8000473c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004740:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004744:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004748:	0023d517          	auipc	a0,0x23d
    8000474c:	30850513          	addi	a0,a0,776 # 80241a50 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	6be080e7          	jalr	1726(ra) # 80000e0e <release>

  if(ff.type == FD_PIPE){
    80004758:	4785                	li	a5,1
    8000475a:	04f90d63          	beq	s2,a5,800047b4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000475e:	3979                	addiw	s2,s2,-2
    80004760:	4785                	li	a5,1
    80004762:	0527e063          	bltu	a5,s2,800047a2 <fileclose+0xa8>
    begin_op();
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	ac2080e7          	jalr	-1342(ra) # 80004228 <begin_op>
    iput(ff.ip);
    8000476e:	854e                	mv	a0,s3
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	2b2080e7          	jalr	690(ra) # 80003a22 <iput>
    end_op();
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	b30080e7          	jalr	-1232(ra) # 800042a8 <end_op>
    80004780:	a00d                	j	800047a2 <fileclose+0xa8>
    panic("fileclose");
    80004782:	00004517          	auipc	a0,0x4
    80004786:	f4e50513          	addi	a0,a0,-178 # 800086d0 <syscalls+0x248>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	dbe080e7          	jalr	-578(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004792:	0023d517          	auipc	a0,0x23d
    80004796:	2be50513          	addi	a0,a0,702 # 80241a50 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	674080e7          	jalr	1652(ra) # 80000e0e <release>
  }
}
    800047a2:	70e2                	ld	ra,56(sp)
    800047a4:	7442                	ld	s0,48(sp)
    800047a6:	74a2                	ld	s1,40(sp)
    800047a8:	7902                	ld	s2,32(sp)
    800047aa:	69e2                	ld	s3,24(sp)
    800047ac:	6a42                	ld	s4,16(sp)
    800047ae:	6aa2                	ld	s5,8(sp)
    800047b0:	6121                	addi	sp,sp,64
    800047b2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047b4:	85d6                	mv	a1,s5
    800047b6:	8552                	mv	a0,s4
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	372080e7          	jalr	882(ra) # 80004b2a <pipeclose>
    800047c0:	b7cd                	j	800047a2 <fileclose+0xa8>

00000000800047c2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047c2:	715d                	addi	sp,sp,-80
    800047c4:	e486                	sd	ra,72(sp)
    800047c6:	e0a2                	sd	s0,64(sp)
    800047c8:	fc26                	sd	s1,56(sp)
    800047ca:	f84a                	sd	s2,48(sp)
    800047cc:	f44e                	sd	s3,40(sp)
    800047ce:	0880                	addi	s0,sp,80
    800047d0:	84aa                	mv	s1,a0
    800047d2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047d4:	ffffd097          	auipc	ra,0xffffd
    800047d8:	3a4080e7          	jalr	932(ra) # 80001b78 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047dc:	409c                	lw	a5,0(s1)
    800047de:	37f9                	addiw	a5,a5,-2
    800047e0:	4705                	li	a4,1
    800047e2:	04f76763          	bltu	a4,a5,80004830 <filestat+0x6e>
    800047e6:	892a                	mv	s2,a0
    ilock(f->ip);
    800047e8:	6c88                	ld	a0,24(s1)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	07e080e7          	jalr	126(ra) # 80003868 <ilock>
    stati(f->ip, &st);
    800047f2:	fb840593          	addi	a1,s0,-72
    800047f6:	6c88                	ld	a0,24(s1)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	2fa080e7          	jalr	762(ra) # 80003af2 <stati>
    iunlock(f->ip);
    80004800:	6c88                	ld	a0,24(s1)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	128080e7          	jalr	296(ra) # 8000392a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000480a:	46e1                	li	a3,24
    8000480c:	fb840613          	addi	a2,s0,-72
    80004810:	85ce                	mv	a1,s3
    80004812:	05093503          	ld	a0,80(s2)
    80004816:	ffffd097          	auipc	ra,0xffffd
    8000481a:	ff2080e7          	jalr	-14(ra) # 80001808 <copyout>
    8000481e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004822:	60a6                	ld	ra,72(sp)
    80004824:	6406                	ld	s0,64(sp)
    80004826:	74e2                	ld	s1,56(sp)
    80004828:	7942                	ld	s2,48(sp)
    8000482a:	79a2                	ld	s3,40(sp)
    8000482c:	6161                	addi	sp,sp,80
    8000482e:	8082                	ret
  return -1;
    80004830:	557d                	li	a0,-1
    80004832:	bfc5                	j	80004822 <filestat+0x60>

0000000080004834 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004834:	7179                	addi	sp,sp,-48
    80004836:	f406                	sd	ra,40(sp)
    80004838:	f022                	sd	s0,32(sp)
    8000483a:	ec26                	sd	s1,24(sp)
    8000483c:	e84a                	sd	s2,16(sp)
    8000483e:	e44e                	sd	s3,8(sp)
    80004840:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004842:	00854783          	lbu	a5,8(a0)
    80004846:	c3d5                	beqz	a5,800048ea <fileread+0xb6>
    80004848:	84aa                	mv	s1,a0
    8000484a:	89ae                	mv	s3,a1
    8000484c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484e:	411c                	lw	a5,0(a0)
    80004850:	4705                	li	a4,1
    80004852:	04e78963          	beq	a5,a4,800048a4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004856:	470d                	li	a4,3
    80004858:	04e78d63          	beq	a5,a4,800048b2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000485c:	4709                	li	a4,2
    8000485e:	06e79e63          	bne	a5,a4,800048da <fileread+0xa6>
    ilock(f->ip);
    80004862:	6d08                	ld	a0,24(a0)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	004080e7          	jalr	4(ra) # 80003868 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000486c:	874a                	mv	a4,s2
    8000486e:	5094                	lw	a3,32(s1)
    80004870:	864e                	mv	a2,s3
    80004872:	4585                	li	a1,1
    80004874:	6c88                	ld	a0,24(s1)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	2a6080e7          	jalr	678(ra) # 80003b1c <readi>
    8000487e:	892a                	mv	s2,a0
    80004880:	00a05563          	blez	a0,8000488a <fileread+0x56>
      f->off += r;
    80004884:	509c                	lw	a5,32(s1)
    80004886:	9fa9                	addw	a5,a5,a0
    80004888:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000488a:	6c88                	ld	a0,24(s1)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	09e080e7          	jalr	158(ra) # 8000392a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004894:	854a                	mv	a0,s2
    80004896:	70a2                	ld	ra,40(sp)
    80004898:	7402                	ld	s0,32(sp)
    8000489a:	64e2                	ld	s1,24(sp)
    8000489c:	6942                	ld	s2,16(sp)
    8000489e:	69a2                	ld	s3,8(sp)
    800048a0:	6145                	addi	sp,sp,48
    800048a2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048a4:	6908                	ld	a0,16(a0)
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	418080e7          	jalr	1048(ra) # 80004cbe <piperead>
    800048ae:	892a                	mv	s2,a0
    800048b0:	b7d5                	j	80004894 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048b2:	02451783          	lh	a5,36(a0)
    800048b6:	03079693          	slli	a3,a5,0x30
    800048ba:	92c1                	srli	a3,a3,0x30
    800048bc:	4725                	li	a4,9
    800048be:	02d76863          	bltu	a4,a3,800048ee <fileread+0xba>
    800048c2:	0792                	slli	a5,a5,0x4
    800048c4:	0023d717          	auipc	a4,0x23d
    800048c8:	0ec70713          	addi	a4,a4,236 # 802419b0 <devsw>
    800048cc:	97ba                	add	a5,a5,a4
    800048ce:	639c                	ld	a5,0(a5)
    800048d0:	c38d                	beqz	a5,800048f2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048d2:	4505                	li	a0,1
    800048d4:	9782                	jalr	a5
    800048d6:	892a                	mv	s2,a0
    800048d8:	bf75                	j	80004894 <fileread+0x60>
    panic("fileread");
    800048da:	00004517          	auipc	a0,0x4
    800048de:	e0650513          	addi	a0,a0,-506 # 800086e0 <syscalls+0x258>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	c66080e7          	jalr	-922(ra) # 80000548 <panic>
    return -1;
    800048ea:	597d                	li	s2,-1
    800048ec:	b765                	j	80004894 <fileread+0x60>
      return -1;
    800048ee:	597d                	li	s2,-1
    800048f0:	b755                	j	80004894 <fileread+0x60>
    800048f2:	597d                	li	s2,-1
    800048f4:	b745                	j	80004894 <fileread+0x60>

00000000800048f6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048f6:	00954783          	lbu	a5,9(a0)
    800048fa:	14078563          	beqz	a5,80004a44 <filewrite+0x14e>
{
    800048fe:	715d                	addi	sp,sp,-80
    80004900:	e486                	sd	ra,72(sp)
    80004902:	e0a2                	sd	s0,64(sp)
    80004904:	fc26                	sd	s1,56(sp)
    80004906:	f84a                	sd	s2,48(sp)
    80004908:	f44e                	sd	s3,40(sp)
    8000490a:	f052                	sd	s4,32(sp)
    8000490c:	ec56                	sd	s5,24(sp)
    8000490e:	e85a                	sd	s6,16(sp)
    80004910:	e45e                	sd	s7,8(sp)
    80004912:	e062                	sd	s8,0(sp)
    80004914:	0880                	addi	s0,sp,80
    80004916:	892a                	mv	s2,a0
    80004918:	8aae                	mv	s5,a1
    8000491a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000491c:	411c                	lw	a5,0(a0)
    8000491e:	4705                	li	a4,1
    80004920:	02e78263          	beq	a5,a4,80004944 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004924:	470d                	li	a4,3
    80004926:	02e78563          	beq	a5,a4,80004950 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000492a:	4709                	li	a4,2
    8000492c:	10e79463          	bne	a5,a4,80004a34 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004930:	0ec05e63          	blez	a2,80004a2c <filewrite+0x136>
    int i = 0;
    80004934:	4981                	li	s3,0
    80004936:	6b05                	lui	s6,0x1
    80004938:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000493c:	6b85                	lui	s7,0x1
    8000493e:	c00b8b9b          	addiw	s7,s7,-1024
    80004942:	a851                	j	800049d6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004944:	6908                	ld	a0,16(a0)
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	254080e7          	jalr	596(ra) # 80004b9a <pipewrite>
    8000494e:	a85d                	j	80004a04 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004950:	02451783          	lh	a5,36(a0)
    80004954:	03079693          	slli	a3,a5,0x30
    80004958:	92c1                	srli	a3,a3,0x30
    8000495a:	4725                	li	a4,9
    8000495c:	0ed76663          	bltu	a4,a3,80004a48 <filewrite+0x152>
    80004960:	0792                	slli	a5,a5,0x4
    80004962:	0023d717          	auipc	a4,0x23d
    80004966:	04e70713          	addi	a4,a4,78 # 802419b0 <devsw>
    8000496a:	97ba                	add	a5,a5,a4
    8000496c:	679c                	ld	a5,8(a5)
    8000496e:	cff9                	beqz	a5,80004a4c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004970:	4505                	li	a0,1
    80004972:	9782                	jalr	a5
    80004974:	a841                	j	80004a04 <filewrite+0x10e>
    80004976:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	8ae080e7          	jalr	-1874(ra) # 80004228 <begin_op>
      ilock(f->ip);
    80004982:	01893503          	ld	a0,24(s2)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	ee2080e7          	jalr	-286(ra) # 80003868 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000498e:	8762                	mv	a4,s8
    80004990:	02092683          	lw	a3,32(s2)
    80004994:	01598633          	add	a2,s3,s5
    80004998:	4585                	li	a1,1
    8000499a:	01893503          	ld	a0,24(s2)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	276080e7          	jalr	630(ra) # 80003c14 <writei>
    800049a6:	84aa                	mv	s1,a0
    800049a8:	02a05f63          	blez	a0,800049e6 <filewrite+0xf0>
        f->off += r;
    800049ac:	02092783          	lw	a5,32(s2)
    800049b0:	9fa9                	addw	a5,a5,a0
    800049b2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049b6:	01893503          	ld	a0,24(s2)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	f70080e7          	jalr	-144(ra) # 8000392a <iunlock>
      end_op();
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	8e6080e7          	jalr	-1818(ra) # 800042a8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049ca:	049c1963          	bne	s8,s1,80004a1c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049ce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049d2:	0349d663          	bge	s3,s4,800049fe <filewrite+0x108>
      int n1 = n - i;
    800049d6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049da:	84be                	mv	s1,a5
    800049dc:	2781                	sext.w	a5,a5
    800049de:	f8fb5ce3          	bge	s6,a5,80004976 <filewrite+0x80>
    800049e2:	84de                	mv	s1,s7
    800049e4:	bf49                	j	80004976 <filewrite+0x80>
      iunlock(f->ip);
    800049e6:	01893503          	ld	a0,24(s2)
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	f40080e7          	jalr	-192(ra) # 8000392a <iunlock>
      end_op();
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	8b6080e7          	jalr	-1866(ra) # 800042a8 <end_op>
      if(r < 0)
    800049fa:	fc04d8e3          	bgez	s1,800049ca <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049fe:	8552                	mv	a0,s4
    80004a00:	033a1863          	bne	s4,s3,80004a30 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a04:	60a6                	ld	ra,72(sp)
    80004a06:	6406                	ld	s0,64(sp)
    80004a08:	74e2                	ld	s1,56(sp)
    80004a0a:	7942                	ld	s2,48(sp)
    80004a0c:	79a2                	ld	s3,40(sp)
    80004a0e:	7a02                	ld	s4,32(sp)
    80004a10:	6ae2                	ld	s5,24(sp)
    80004a12:	6b42                	ld	s6,16(sp)
    80004a14:	6ba2                	ld	s7,8(sp)
    80004a16:	6c02                	ld	s8,0(sp)
    80004a18:	6161                	addi	sp,sp,80
    80004a1a:	8082                	ret
        panic("short filewrite");
    80004a1c:	00004517          	auipc	a0,0x4
    80004a20:	cd450513          	addi	a0,a0,-812 # 800086f0 <syscalls+0x268>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	b24080e7          	jalr	-1244(ra) # 80000548 <panic>
    int i = 0;
    80004a2c:	4981                	li	s3,0
    80004a2e:	bfc1                	j	800049fe <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a30:	557d                	li	a0,-1
    80004a32:	bfc9                	j	80004a04 <filewrite+0x10e>
    panic("filewrite");
    80004a34:	00004517          	auipc	a0,0x4
    80004a38:	ccc50513          	addi	a0,a0,-820 # 80008700 <syscalls+0x278>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	b0c080e7          	jalr	-1268(ra) # 80000548 <panic>
    return -1;
    80004a44:	557d                	li	a0,-1
}
    80004a46:	8082                	ret
      return -1;
    80004a48:	557d                	li	a0,-1
    80004a4a:	bf6d                	j	80004a04 <filewrite+0x10e>
    80004a4c:	557d                	li	a0,-1
    80004a4e:	bf5d                	j	80004a04 <filewrite+0x10e>

0000000080004a50 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a50:	7179                	addi	sp,sp,-48
    80004a52:	f406                	sd	ra,40(sp)
    80004a54:	f022                	sd	s0,32(sp)
    80004a56:	ec26                	sd	s1,24(sp)
    80004a58:	e84a                	sd	s2,16(sp)
    80004a5a:	e44e                	sd	s3,8(sp)
    80004a5c:	e052                	sd	s4,0(sp)
    80004a5e:	1800                	addi	s0,sp,48
    80004a60:	84aa                	mv	s1,a0
    80004a62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a64:	0005b023          	sd	zero,0(a1)
    80004a68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	bd2080e7          	jalr	-1070(ra) # 8000463e <filealloc>
    80004a74:	e088                	sd	a0,0(s1)
    80004a76:	c551                	beqz	a0,80004b02 <pipealloc+0xb2>
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	bc6080e7          	jalr	-1082(ra) # 8000463e <filealloc>
    80004a80:	00aa3023          	sd	a0,0(s4)
    80004a84:	c92d                	beqz	a0,80004af6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	1a2080e7          	jalr	418(ra) # 80000c28 <kalloc>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	c125                	beqz	a0,80004af0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a92:	4985                	li	s3,1
    80004a94:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a98:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a9c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa4:	00004597          	auipc	a1,0x4
    80004aa8:	c6c58593          	addi	a1,a1,-916 # 80008710 <syscalls+0x288>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	21e080e7          	jalr	542(ra) # 80000cca <initlock>
  (*f0)->type = FD_PIPE;
    80004ab4:	609c                	ld	a5,0(s1)
    80004ab6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aba:	609c                	ld	a5,0(s1)
    80004abc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac0:	609c                	ld	a5,0(s1)
    80004ac2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ac6:	609c                	ld	a5,0(s1)
    80004ac8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004acc:	000a3783          	ld	a5,0(s4)
    80004ad0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad4:	000a3783          	ld	a5,0(s4)
    80004ad8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004adc:	000a3783          	ld	a5,0(s4)
    80004ae0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae4:	000a3783          	ld	a5,0(s4)
    80004ae8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aec:	4501                	li	a0,0
    80004aee:	a025                	j	80004b16 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af0:	6088                	ld	a0,0(s1)
    80004af2:	e501                	bnez	a0,80004afa <pipealloc+0xaa>
    80004af4:	a039                	j	80004b02 <pipealloc+0xb2>
    80004af6:	6088                	ld	a0,0(s1)
    80004af8:	c51d                	beqz	a0,80004b26 <pipealloc+0xd6>
    fileclose(*f0);
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	c00080e7          	jalr	-1024(ra) # 800046fa <fileclose>
  if(*f1)
    80004b02:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b06:	557d                	li	a0,-1
  if(*f1)
    80004b08:	c799                	beqz	a5,80004b16 <pipealloc+0xc6>
    fileclose(*f1);
    80004b0a:	853e                	mv	a0,a5
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	bee080e7          	jalr	-1042(ra) # 800046fa <fileclose>
  return -1;
    80004b14:	557d                	li	a0,-1
}
    80004b16:	70a2                	ld	ra,40(sp)
    80004b18:	7402                	ld	s0,32(sp)
    80004b1a:	64e2                	ld	s1,24(sp)
    80004b1c:	6942                	ld	s2,16(sp)
    80004b1e:	69a2                	ld	s3,8(sp)
    80004b20:	6a02                	ld	s4,0(sp)
    80004b22:	6145                	addi	sp,sp,48
    80004b24:	8082                	ret
  return -1;
    80004b26:	557d                	li	a0,-1
    80004b28:	b7fd                	j	80004b16 <pipealloc+0xc6>

0000000080004b2a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b2a:	1101                	addi	sp,sp,-32
    80004b2c:	ec06                	sd	ra,24(sp)
    80004b2e:	e822                	sd	s0,16(sp)
    80004b30:	e426                	sd	s1,8(sp)
    80004b32:	e04a                	sd	s2,0(sp)
    80004b34:	1000                	addi	s0,sp,32
    80004b36:	84aa                	mv	s1,a0
    80004b38:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	220080e7          	jalr	544(ra) # 80000d5a <acquire>
  if(writable){
    80004b42:	02090d63          	beqz	s2,80004b7c <pipeclose+0x52>
    pi->writeopen = 0;
    80004b46:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b4a:	21848513          	addi	a0,s1,536
    80004b4e:	ffffe097          	auipc	ra,0xffffe
    80004b52:	9c0080e7          	jalr	-1600(ra) # 8000250e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b56:	2204b783          	ld	a5,544(s1)
    80004b5a:	eb95                	bnez	a5,80004b8e <pipeclose+0x64>
    release(&pi->lock);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	2b0080e7          	jalr	688(ra) # 80000e0e <release>
    kfree((char*)pi);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	f38080e7          	jalr	-200(ra) # 80000aa0 <kfree>
  } else
    release(&pi->lock);
}
    80004b70:	60e2                	ld	ra,24(sp)
    80004b72:	6442                	ld	s0,16(sp)
    80004b74:	64a2                	ld	s1,8(sp)
    80004b76:	6902                	ld	s2,0(sp)
    80004b78:	6105                	addi	sp,sp,32
    80004b7a:	8082                	ret
    pi->readopen = 0;
    80004b7c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b80:	21c48513          	addi	a0,s1,540
    80004b84:	ffffe097          	auipc	ra,0xffffe
    80004b88:	98a080e7          	jalr	-1654(ra) # 8000250e <wakeup>
    80004b8c:	b7e9                	j	80004b56 <pipeclose+0x2c>
    release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	27e080e7          	jalr	638(ra) # 80000e0e <release>
}
    80004b98:	bfe1                	j	80004b70 <pipeclose+0x46>

0000000080004b9a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b9a:	7119                	addi	sp,sp,-128
    80004b9c:	fc86                	sd	ra,120(sp)
    80004b9e:	f8a2                	sd	s0,112(sp)
    80004ba0:	f4a6                	sd	s1,104(sp)
    80004ba2:	f0ca                	sd	s2,96(sp)
    80004ba4:	ecce                	sd	s3,88(sp)
    80004ba6:	e8d2                	sd	s4,80(sp)
    80004ba8:	e4d6                	sd	s5,72(sp)
    80004baa:	e0da                	sd	s6,64(sp)
    80004bac:	fc5e                	sd	s7,56(sp)
    80004bae:	f862                	sd	s8,48(sp)
    80004bb0:	f466                	sd	s9,40(sp)
    80004bb2:	f06a                	sd	s10,32(sp)
    80004bb4:	ec6e                	sd	s11,24(sp)
    80004bb6:	0100                	addi	s0,sp,128
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	8cae                	mv	s9,a1
    80004bbc:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	fba080e7          	jalr	-70(ra) # 80001b78 <myproc>
    80004bc6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	190080e7          	jalr	400(ra) # 80000d5a <acquire>
  for(i = 0; i < n; i++){
    80004bd2:	0d605963          	blez	s6,80004ca4 <pipewrite+0x10a>
    80004bd6:	89a6                	mv	s3,s1
    80004bd8:	3b7d                	addiw	s6,s6,-1
    80004bda:	1b02                	slli	s6,s6,0x20
    80004bdc:	020b5b13          	srli	s6,s6,0x20
    80004be0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004be2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004be6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bea:	5dfd                	li	s11,-1
    80004bec:	000b8d1b          	sext.w	s10,s7
    80004bf0:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bf2:	2184a783          	lw	a5,536(s1)
    80004bf6:	21c4a703          	lw	a4,540(s1)
    80004bfa:	2007879b          	addiw	a5,a5,512
    80004bfe:	02f71b63          	bne	a4,a5,80004c34 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c02:	2204a783          	lw	a5,544(s1)
    80004c06:	cbad                	beqz	a5,80004c78 <pipewrite+0xde>
    80004c08:	03092783          	lw	a5,48(s2)
    80004c0c:	e7b5                	bnez	a5,80004c78 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004c0e:	8556                	mv	a0,s5
    80004c10:	ffffe097          	auipc	ra,0xffffe
    80004c14:	8fe080e7          	jalr	-1794(ra) # 8000250e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c18:	85ce                	mv	a1,s3
    80004c1a:	8552                	mv	a0,s4
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	76c080e7          	jalr	1900(ra) # 80002388 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c24:	2184a783          	lw	a5,536(s1)
    80004c28:	21c4a703          	lw	a4,540(s1)
    80004c2c:	2007879b          	addiw	a5,a5,512
    80004c30:	fcf709e3          	beq	a4,a5,80004c02 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c34:	4685                	li	a3,1
    80004c36:	019b8633          	add	a2,s7,s9
    80004c3a:	f8f40593          	addi	a1,s0,-113
    80004c3e:	05093503          	ld	a0,80(s2)
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	cb6080e7          	jalr	-842(ra) # 800018f8 <copyin>
    80004c4a:	05b50e63          	beq	a0,s11,80004ca6 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c4e:	21c4a783          	lw	a5,540(s1)
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ae23          	sw	a4,540(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	f8f44703          	lbu	a4,-113(s0)
    80004c64:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c68:	001d0c1b          	addiw	s8,s10,1
    80004c6c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c70:	036b8b63          	beq	s7,s6,80004ca6 <pipewrite+0x10c>
    80004c74:	8bbe                	mv	s7,a5
    80004c76:	bf9d                	j	80004bec <pipewrite+0x52>
        release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	194080e7          	jalr	404(ra) # 80000e0e <release>
        return -1;
    80004c82:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c84:	8562                	mv	a0,s8
    80004c86:	70e6                	ld	ra,120(sp)
    80004c88:	7446                	ld	s0,112(sp)
    80004c8a:	74a6                	ld	s1,104(sp)
    80004c8c:	7906                	ld	s2,96(sp)
    80004c8e:	69e6                	ld	s3,88(sp)
    80004c90:	6a46                	ld	s4,80(sp)
    80004c92:	6aa6                	ld	s5,72(sp)
    80004c94:	6b06                	ld	s6,64(sp)
    80004c96:	7be2                	ld	s7,56(sp)
    80004c98:	7c42                	ld	s8,48(sp)
    80004c9a:	7ca2                	ld	s9,40(sp)
    80004c9c:	7d02                	ld	s10,32(sp)
    80004c9e:	6de2                	ld	s11,24(sp)
    80004ca0:	6109                	addi	sp,sp,128
    80004ca2:	8082                	ret
  for(i = 0; i < n; i++){
    80004ca4:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004ca6:	21848513          	addi	a0,s1,536
    80004caa:	ffffe097          	auipc	ra,0xffffe
    80004cae:	864080e7          	jalr	-1948(ra) # 8000250e <wakeup>
  release(&pi->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	15a080e7          	jalr	346(ra) # 80000e0e <release>
  return i;
    80004cbc:	b7e1                	j	80004c84 <pipewrite+0xea>

0000000080004cbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	715d                	addi	sp,sp,-80
    80004cc0:	e486                	sd	ra,72(sp)
    80004cc2:	e0a2                	sd	s0,64(sp)
    80004cc4:	fc26                	sd	s1,56(sp)
    80004cc6:	f84a                	sd	s2,48(sp)
    80004cc8:	f44e                	sd	s3,40(sp)
    80004cca:	f052                	sd	s4,32(sp)
    80004ccc:	ec56                	sd	s5,24(sp)
    80004cce:	e85a                	sd	s6,16(sp)
    80004cd0:	0880                	addi	s0,sp,80
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	892e                	mv	s2,a1
    80004cd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	ea0080e7          	jalr	-352(ra) # 80001b78 <myproc>
    80004ce0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ce2:	8b26                	mv	s6,s1
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	074080e7          	jalr	116(ra) # 80000d5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cee:	2184a703          	lw	a4,536(s1)
    80004cf2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfa:	02f71463          	bne	a4,a5,80004d22 <piperead+0x64>
    80004cfe:	2244a783          	lw	a5,548(s1)
    80004d02:	c385                	beqz	a5,80004d22 <piperead+0x64>
    if(pr->killed){
    80004d04:	030a2783          	lw	a5,48(s4)
    80004d08:	ebc1                	bnez	a5,80004d98 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0a:	85da                	mv	a1,s6
    80004d0c:	854e                	mv	a0,s3
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	67a080e7          	jalr	1658(ra) # 80002388 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d16:	2184a703          	lw	a4,536(s1)
    80004d1a:	21c4a783          	lw	a5,540(s1)
    80004d1e:	fef700e3          	beq	a4,a5,80004cfe <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d22:	09505263          	blez	s5,80004da6 <piperead+0xe8>
    80004d26:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d28:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d2a:	2184a783          	lw	a5,536(s1)
    80004d2e:	21c4a703          	lw	a4,540(s1)
    80004d32:	02f70d63          	beq	a4,a5,80004d6c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d36:	0017871b          	addiw	a4,a5,1
    80004d3a:	20e4ac23          	sw	a4,536(s1)
    80004d3e:	1ff7f793          	andi	a5,a5,511
    80004d42:	97a6                	add	a5,a5,s1
    80004d44:	0187c783          	lbu	a5,24(a5)
    80004d48:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4c:	4685                	li	a3,1
    80004d4e:	fbf40613          	addi	a2,s0,-65
    80004d52:	85ca                	mv	a1,s2
    80004d54:	050a3503          	ld	a0,80(s4)
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	ab0080e7          	jalr	-1360(ra) # 80001808 <copyout>
    80004d60:	01650663          	beq	a0,s6,80004d6c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d64:	2985                	addiw	s3,s3,1
    80004d66:	0905                	addi	s2,s2,1
    80004d68:	fd3a91e3          	bne	s5,s3,80004d2a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d6c:	21c48513          	addi	a0,s1,540
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	79e080e7          	jalr	1950(ra) # 8000250e <wakeup>
  release(&pi->lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	094080e7          	jalr	148(ra) # 80000e0e <release>
  return i;
}
    80004d82:	854e                	mv	a0,s3
    80004d84:	60a6                	ld	ra,72(sp)
    80004d86:	6406                	ld	s0,64(sp)
    80004d88:	74e2                	ld	s1,56(sp)
    80004d8a:	7942                	ld	s2,48(sp)
    80004d8c:	79a2                	ld	s3,40(sp)
    80004d8e:	7a02                	ld	s4,32(sp)
    80004d90:	6ae2                	ld	s5,24(sp)
    80004d92:	6b42                	ld	s6,16(sp)
    80004d94:	6161                	addi	sp,sp,80
    80004d96:	8082                	ret
      release(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	074080e7          	jalr	116(ra) # 80000e0e <release>
      return -1;
    80004da2:	59fd                	li	s3,-1
    80004da4:	bff9                	j	80004d82 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004da6:	4981                	li	s3,0
    80004da8:	b7d1                	j	80004d6c <piperead+0xae>

0000000080004daa <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004daa:	df010113          	addi	sp,sp,-528
    80004dae:	20113423          	sd	ra,520(sp)
    80004db2:	20813023          	sd	s0,512(sp)
    80004db6:	ffa6                	sd	s1,504(sp)
    80004db8:	fbca                	sd	s2,496(sp)
    80004dba:	f7ce                	sd	s3,488(sp)
    80004dbc:	f3d2                	sd	s4,480(sp)
    80004dbe:	efd6                	sd	s5,472(sp)
    80004dc0:	ebda                	sd	s6,464(sp)
    80004dc2:	e7de                	sd	s7,456(sp)
    80004dc4:	e3e2                	sd	s8,448(sp)
    80004dc6:	ff66                	sd	s9,440(sp)
    80004dc8:	fb6a                	sd	s10,432(sp)
    80004dca:	f76e                	sd	s11,424(sp)
    80004dcc:	0c00                	addi	s0,sp,528
    80004dce:	84aa                	mv	s1,a0
    80004dd0:	dea43c23          	sd	a0,-520(s0)
    80004dd4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	da0080e7          	jalr	-608(ra) # 80001b78 <myproc>
    80004de0:	892a                	mv	s2,a0

  begin_op();
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	446080e7          	jalr	1094(ra) # 80004228 <begin_op>

  if((ip = namei(path)) == 0){
    80004dea:	8526                	mv	a0,s1
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	230080e7          	jalr	560(ra) # 8000401c <namei>
    80004df4:	c92d                	beqz	a0,80004e66 <exec+0xbc>
    80004df6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	a70080e7          	jalr	-1424(ra) # 80003868 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e00:	04000713          	li	a4,64
    80004e04:	4681                	li	a3,0
    80004e06:	e4840613          	addi	a2,s0,-440
    80004e0a:	4581                	li	a1,0
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	d0e080e7          	jalr	-754(ra) # 80003b1c <readi>
    80004e16:	04000793          	li	a5,64
    80004e1a:	00f51a63          	bne	a0,a5,80004e2e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e1e:	e4842703          	lw	a4,-440(s0)
    80004e22:	464c47b7          	lui	a5,0x464c4
    80004e26:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e2a:	04f70463          	beq	a4,a5,80004e72 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e2e:	8526                	mv	a0,s1
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	c9a080e7          	jalr	-870(ra) # 80003aca <iunlockput>
    end_op();
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	470080e7          	jalr	1136(ra) # 800042a8 <end_op>
  }
  return -1;
    80004e40:	557d                	li	a0,-1
}
    80004e42:	20813083          	ld	ra,520(sp)
    80004e46:	20013403          	ld	s0,512(sp)
    80004e4a:	74fe                	ld	s1,504(sp)
    80004e4c:	795e                	ld	s2,496(sp)
    80004e4e:	79be                	ld	s3,488(sp)
    80004e50:	7a1e                	ld	s4,480(sp)
    80004e52:	6afe                	ld	s5,472(sp)
    80004e54:	6b5e                	ld	s6,464(sp)
    80004e56:	6bbe                	ld	s7,456(sp)
    80004e58:	6c1e                	ld	s8,448(sp)
    80004e5a:	7cfa                	ld	s9,440(sp)
    80004e5c:	7d5a                	ld	s10,432(sp)
    80004e5e:	7dba                	ld	s11,424(sp)
    80004e60:	21010113          	addi	sp,sp,528
    80004e64:	8082                	ret
    end_op();
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	442080e7          	jalr	1090(ra) # 800042a8 <end_op>
    return -1;
    80004e6e:	557d                	li	a0,-1
    80004e70:	bfc9                	j	80004e42 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e72:	854a                	mv	a0,s2
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	dc8080e7          	jalr	-568(ra) # 80001c3c <proc_pagetable>
    80004e7c:	8baa                	mv	s7,a0
    80004e7e:	d945                	beqz	a0,80004e2e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e80:	e6842983          	lw	s3,-408(s0)
    80004e84:	e8045783          	lhu	a5,-384(s0)
    80004e88:	c7ad                	beqz	a5,80004ef2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e8a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e8e:	6c85                	lui	s9,0x1
    80004e90:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e94:	def43823          	sd	a5,-528(s0)
    80004e98:	a42d                	j	800050c2 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e9a:	00004517          	auipc	a0,0x4
    80004e9e:	87e50513          	addi	a0,a0,-1922 # 80008718 <syscalls+0x290>
    80004ea2:	ffffb097          	auipc	ra,0xffffb
    80004ea6:	6a6080e7          	jalr	1702(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eaa:	8756                	mv	a4,s5
    80004eac:	012d86bb          	addw	a3,s11,s2
    80004eb0:	4581                	li	a1,0
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	c68080e7          	jalr	-920(ra) # 80003b1c <readi>
    80004ebc:	2501                	sext.w	a0,a0
    80004ebe:	1aaa9963          	bne	s5,a0,80005070 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ec2:	6785                	lui	a5,0x1
    80004ec4:	0127893b          	addw	s2,a5,s2
    80004ec8:	77fd                	lui	a5,0xfffff
    80004eca:	01478a3b          	addw	s4,a5,s4
    80004ece:	1f897163          	bgeu	s2,s8,800050b0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ed2:	02091593          	slli	a1,s2,0x20
    80004ed6:	9181                	srli	a1,a1,0x20
    80004ed8:	95ea                	add	a1,a1,s10
    80004eda:	855e                	mv	a0,s7
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	30c080e7          	jalr	780(ra) # 800011e8 <walkaddr>
    80004ee4:	862a                	mv	a2,a0
    if(pa == 0)
    80004ee6:	d955                	beqz	a0,80004e9a <exec+0xf0>
      n = PGSIZE;
    80004ee8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004eea:	fd9a70e3          	bgeu	s4,s9,80004eaa <exec+0x100>
      n = sz - i;
    80004eee:	8ad2                	mv	s5,s4
    80004ef0:	bf6d                	j	80004eaa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ef2:	4901                	li	s2,0
  iunlockput(ip);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	bd4080e7          	jalr	-1068(ra) # 80003aca <iunlockput>
  end_op();
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	3aa080e7          	jalr	938(ra) # 800042a8 <end_op>
  p = myproc();
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	c72080e7          	jalr	-910(ra) # 80001b78 <myproc>
    80004f0e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f10:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f14:	6785                	lui	a5,0x1
    80004f16:	17fd                	addi	a5,a5,-1
    80004f18:	993e                	add	s2,s2,a5
    80004f1a:	757d                	lui	a0,0xfffff
    80004f1c:	00a977b3          	and	a5,s2,a0
    80004f20:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f24:	6609                	lui	a2,0x2
    80004f26:	963e                	add	a2,a2,a5
    80004f28:	85be                	mv	a1,a5
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	6a0080e7          	jalr	1696(ra) # 800015cc <uvmalloc>
    80004f34:	8b2a                	mv	s6,a0
  ip = 0;
    80004f36:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f38:	12050c63          	beqz	a0,80005070 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f3c:	75f9                	lui	a1,0xffffe
    80004f3e:	95aa                	add	a1,a1,a0
    80004f40:	855e                	mv	a0,s7
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	894080e7          	jalr	-1900(ra) # 800017d6 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f4a:	7c7d                	lui	s8,0xfffff
    80004f4c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f4e:	e0043783          	ld	a5,-512(s0)
    80004f52:	6388                	ld	a0,0(a5)
    80004f54:	c535                	beqz	a0,80004fc0 <exec+0x216>
    80004f56:	e8840993          	addi	s3,s0,-376
    80004f5a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f5e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	07e080e7          	jalr	126(ra) # 80000fde <strlen>
    80004f68:	2505                	addiw	a0,a0,1
    80004f6a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f6e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f72:	13896363          	bltu	s2,s8,80005098 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f76:	e0043d83          	ld	s11,-512(s0)
    80004f7a:	000dba03          	ld	s4,0(s11)
    80004f7e:	8552                	mv	a0,s4
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	05e080e7          	jalr	94(ra) # 80000fde <strlen>
    80004f88:	0015069b          	addiw	a3,a0,1
    80004f8c:	8652                	mv	a2,s4
    80004f8e:	85ca                	mv	a1,s2
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	876080e7          	jalr	-1930(ra) # 80001808 <copyout>
    80004f9a:	10054363          	bltz	a0,800050a0 <exec+0x2f6>
    ustack[argc] = sp;
    80004f9e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fa2:	0485                	addi	s1,s1,1
    80004fa4:	008d8793          	addi	a5,s11,8
    80004fa8:	e0f43023          	sd	a5,-512(s0)
    80004fac:	008db503          	ld	a0,8(s11)
    80004fb0:	c911                	beqz	a0,80004fc4 <exec+0x21a>
    if(argc >= MAXARG)
    80004fb2:	09a1                	addi	s3,s3,8
    80004fb4:	fb3c96e3          	bne	s9,s3,80004f60 <exec+0x1b6>
  sz = sz1;
    80004fb8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fbc:	4481                	li	s1,0
    80004fbe:	a84d                	j	80005070 <exec+0x2c6>
  sp = sz;
    80004fc0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fc2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fc4:	00349793          	slli	a5,s1,0x3
    80004fc8:	f9040713          	addi	a4,s0,-112
    80004fcc:	97ba                	add	a5,a5,a4
    80004fce:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004fd2:	00148693          	addi	a3,s1,1
    80004fd6:	068e                	slli	a3,a3,0x3
    80004fd8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fdc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fe0:	01897663          	bgeu	s2,s8,80004fec <exec+0x242>
  sz = sz1;
    80004fe4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe8:	4481                	li	s1,0
    80004fea:	a059                	j	80005070 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fec:	e8840613          	addi	a2,s0,-376
    80004ff0:	85ca                	mv	a1,s2
    80004ff2:	855e                	mv	a0,s7
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	814080e7          	jalr	-2028(ra) # 80001808 <copyout>
    80004ffc:	0a054663          	bltz	a0,800050a8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005000:	058ab783          	ld	a5,88(s5)
    80005004:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005008:	df843783          	ld	a5,-520(s0)
    8000500c:	0007c703          	lbu	a4,0(a5)
    80005010:	cf11                	beqz	a4,8000502c <exec+0x282>
    80005012:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005014:	02f00693          	li	a3,47
    80005018:	a029                	j	80005022 <exec+0x278>
  for(last=s=path; *s; s++)
    8000501a:	0785                	addi	a5,a5,1
    8000501c:	fff7c703          	lbu	a4,-1(a5)
    80005020:	c711                	beqz	a4,8000502c <exec+0x282>
    if(*s == '/')
    80005022:	fed71ce3          	bne	a4,a3,8000501a <exec+0x270>
      last = s+1;
    80005026:	def43c23          	sd	a5,-520(s0)
    8000502a:	bfc5                	j	8000501a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000502c:	4641                	li	a2,16
    8000502e:	df843583          	ld	a1,-520(s0)
    80005032:	158a8513          	addi	a0,s5,344
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	f76080e7          	jalr	-138(ra) # 80000fac <safestrcpy>
  oldpagetable = p->pagetable;
    8000503e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005042:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005046:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000504a:	058ab783          	ld	a5,88(s5)
    8000504e:	e6043703          	ld	a4,-416(s0)
    80005052:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005054:	058ab783          	ld	a5,88(s5)
    80005058:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000505c:	85ea                	mv	a1,s10
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	c7a080e7          	jalr	-902(ra) # 80001cd8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005066:	0004851b          	sext.w	a0,s1
    8000506a:	bbe1                	j	80004e42 <exec+0x98>
    8000506c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005070:	e0843583          	ld	a1,-504(s0)
    80005074:	855e                	mv	a0,s7
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	c62080e7          	jalr	-926(ra) # 80001cd8 <proc_freepagetable>
  if(ip){
    8000507e:	da0498e3          	bnez	s1,80004e2e <exec+0x84>
  return -1;
    80005082:	557d                	li	a0,-1
    80005084:	bb7d                	j	80004e42 <exec+0x98>
    80005086:	e1243423          	sd	s2,-504(s0)
    8000508a:	b7dd                	j	80005070 <exec+0x2c6>
    8000508c:	e1243423          	sd	s2,-504(s0)
    80005090:	b7c5                	j	80005070 <exec+0x2c6>
    80005092:	e1243423          	sd	s2,-504(s0)
    80005096:	bfe9                	j	80005070 <exec+0x2c6>
  sz = sz1;
    80005098:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000509c:	4481                	li	s1,0
    8000509e:	bfc9                	j	80005070 <exec+0x2c6>
  sz = sz1;
    800050a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a4:	4481                	li	s1,0
    800050a6:	b7e9                	j	80005070 <exec+0x2c6>
  sz = sz1;
    800050a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ac:	4481                	li	s1,0
    800050ae:	b7c9                	j	80005070 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050b0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b4:	2b05                	addiw	s6,s6,1
    800050b6:	0389899b          	addiw	s3,s3,56
    800050ba:	e8045783          	lhu	a5,-384(s0)
    800050be:	e2fb5be3          	bge	s6,a5,80004ef4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050c2:	2981                	sext.w	s3,s3
    800050c4:	03800713          	li	a4,56
    800050c8:	86ce                	mv	a3,s3
    800050ca:	e1040613          	addi	a2,s0,-496
    800050ce:	4581                	li	a1,0
    800050d0:	8526                	mv	a0,s1
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	a4a080e7          	jalr	-1462(ra) # 80003b1c <readi>
    800050da:	03800793          	li	a5,56
    800050de:	f8f517e3          	bne	a0,a5,8000506c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050e2:	e1042783          	lw	a5,-496(s0)
    800050e6:	4705                	li	a4,1
    800050e8:	fce796e3          	bne	a5,a4,800050b4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050ec:	e3843603          	ld	a2,-456(s0)
    800050f0:	e3043783          	ld	a5,-464(s0)
    800050f4:	f8f669e3          	bltu	a2,a5,80005086 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050f8:	e2043783          	ld	a5,-480(s0)
    800050fc:	963e                	add	a2,a2,a5
    800050fe:	f8f667e3          	bltu	a2,a5,8000508c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005102:	85ca                	mv	a1,s2
    80005104:	855e                	mv	a0,s7
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	4c6080e7          	jalr	1222(ra) # 800015cc <uvmalloc>
    8000510e:	e0a43423          	sd	a0,-504(s0)
    80005112:	d141                	beqz	a0,80005092 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005114:	e2043d03          	ld	s10,-480(s0)
    80005118:	df043783          	ld	a5,-528(s0)
    8000511c:	00fd77b3          	and	a5,s10,a5
    80005120:	fba1                	bnez	a5,80005070 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005122:	e1842d83          	lw	s11,-488(s0)
    80005126:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000512a:	f80c03e3          	beqz	s8,800050b0 <exec+0x306>
    8000512e:	8a62                	mv	s4,s8
    80005130:	4901                	li	s2,0
    80005132:	b345                	j	80004ed2 <exec+0x128>

0000000080005134 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005134:	7179                	addi	sp,sp,-48
    80005136:	f406                	sd	ra,40(sp)
    80005138:	f022                	sd	s0,32(sp)
    8000513a:	ec26                	sd	s1,24(sp)
    8000513c:	e84a                	sd	s2,16(sp)
    8000513e:	1800                	addi	s0,sp,48
    80005140:	892e                	mv	s2,a1
    80005142:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005144:	fdc40593          	addi	a1,s0,-36
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	bae080e7          	jalr	-1106(ra) # 80002cf6 <argint>
    80005150:	04054063          	bltz	a0,80005190 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005154:	fdc42703          	lw	a4,-36(s0)
    80005158:	47bd                	li	a5,15
    8000515a:	02e7ed63          	bltu	a5,a4,80005194 <argfd+0x60>
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	a1a080e7          	jalr	-1510(ra) # 80001b78 <myproc>
    80005166:	fdc42703          	lw	a4,-36(s0)
    8000516a:	01a70793          	addi	a5,a4,26
    8000516e:	078e                	slli	a5,a5,0x3
    80005170:	953e                	add	a0,a0,a5
    80005172:	611c                	ld	a5,0(a0)
    80005174:	c395                	beqz	a5,80005198 <argfd+0x64>
    return -1;
  if(pfd)
    80005176:	00090463          	beqz	s2,8000517e <argfd+0x4a>
    *pfd = fd;
    8000517a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000517e:	4501                	li	a0,0
  if(pf)
    80005180:	c091                	beqz	s1,80005184 <argfd+0x50>
    *pf = f;
    80005182:	e09c                	sd	a5,0(s1)
}
    80005184:	70a2                	ld	ra,40(sp)
    80005186:	7402                	ld	s0,32(sp)
    80005188:	64e2                	ld	s1,24(sp)
    8000518a:	6942                	ld	s2,16(sp)
    8000518c:	6145                	addi	sp,sp,48
    8000518e:	8082                	ret
    return -1;
    80005190:	557d                	li	a0,-1
    80005192:	bfcd                	j	80005184 <argfd+0x50>
    return -1;
    80005194:	557d                	li	a0,-1
    80005196:	b7fd                	j	80005184 <argfd+0x50>
    80005198:	557d                	li	a0,-1
    8000519a:	b7ed                	j	80005184 <argfd+0x50>

000000008000519c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000519c:	1101                	addi	sp,sp,-32
    8000519e:	ec06                	sd	ra,24(sp)
    800051a0:	e822                	sd	s0,16(sp)
    800051a2:	e426                	sd	s1,8(sp)
    800051a4:	1000                	addi	s0,sp,32
    800051a6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	9d0080e7          	jalr	-1584(ra) # 80001b78 <myproc>
    800051b0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051b2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fdb90d0>
    800051b6:	4501                	li	a0,0
    800051b8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ba:	6398                	ld	a4,0(a5)
    800051bc:	cb19                	beqz	a4,800051d2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051be:	2505                	addiw	a0,a0,1
    800051c0:	07a1                	addi	a5,a5,8
    800051c2:	fed51ce3          	bne	a0,a3,800051ba <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051c6:	557d                	li	a0,-1
}
    800051c8:	60e2                	ld	ra,24(sp)
    800051ca:	6442                	ld	s0,16(sp)
    800051cc:	64a2                	ld	s1,8(sp)
    800051ce:	6105                	addi	sp,sp,32
    800051d0:	8082                	ret
      p->ofile[fd] = f;
    800051d2:	01a50793          	addi	a5,a0,26
    800051d6:	078e                	slli	a5,a5,0x3
    800051d8:	963e                	add	a2,a2,a5
    800051da:	e204                	sd	s1,0(a2)
      return fd;
    800051dc:	b7f5                	j	800051c8 <fdalloc+0x2c>

00000000800051de <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051de:	715d                	addi	sp,sp,-80
    800051e0:	e486                	sd	ra,72(sp)
    800051e2:	e0a2                	sd	s0,64(sp)
    800051e4:	fc26                	sd	s1,56(sp)
    800051e6:	f84a                	sd	s2,48(sp)
    800051e8:	f44e                	sd	s3,40(sp)
    800051ea:	f052                	sd	s4,32(sp)
    800051ec:	ec56                	sd	s5,24(sp)
    800051ee:	0880                	addi	s0,sp,80
    800051f0:	89ae                	mv	s3,a1
    800051f2:	8ab2                	mv	s5,a2
    800051f4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051f6:	fb040593          	addi	a1,s0,-80
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	e40080e7          	jalr	-448(ra) # 8000403a <nameiparent>
    80005202:	892a                	mv	s2,a0
    80005204:	12050f63          	beqz	a0,80005342 <create+0x164>
    return 0;

  ilock(dp);
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	660080e7          	jalr	1632(ra) # 80003868 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005210:	4601                	li	a2,0
    80005212:	fb040593          	addi	a1,s0,-80
    80005216:	854a                	mv	a0,s2
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	b32080e7          	jalr	-1230(ra) # 80003d4a <dirlookup>
    80005220:	84aa                	mv	s1,a0
    80005222:	c921                	beqz	a0,80005272 <create+0x94>
    iunlockput(dp);
    80005224:	854a                	mv	a0,s2
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	8a4080e7          	jalr	-1884(ra) # 80003aca <iunlockput>
    ilock(ip);
    8000522e:	8526                	mv	a0,s1
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	638080e7          	jalr	1592(ra) # 80003868 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005238:	2981                	sext.w	s3,s3
    8000523a:	4789                	li	a5,2
    8000523c:	02f99463          	bne	s3,a5,80005264 <create+0x86>
    80005240:	0444d783          	lhu	a5,68(s1)
    80005244:	37f9                	addiw	a5,a5,-2
    80005246:	17c2                	slli	a5,a5,0x30
    80005248:	93c1                	srli	a5,a5,0x30
    8000524a:	4705                	li	a4,1
    8000524c:	00f76c63          	bltu	a4,a5,80005264 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005250:	8526                	mv	a0,s1
    80005252:	60a6                	ld	ra,72(sp)
    80005254:	6406                	ld	s0,64(sp)
    80005256:	74e2                	ld	s1,56(sp)
    80005258:	7942                	ld	s2,48(sp)
    8000525a:	79a2                	ld	s3,40(sp)
    8000525c:	7a02                	ld	s4,32(sp)
    8000525e:	6ae2                	ld	s5,24(sp)
    80005260:	6161                	addi	sp,sp,80
    80005262:	8082                	ret
    iunlockput(ip);
    80005264:	8526                	mv	a0,s1
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	864080e7          	jalr	-1948(ra) # 80003aca <iunlockput>
    return 0;
    8000526e:	4481                	li	s1,0
    80005270:	b7c5                	j	80005250 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005272:	85ce                	mv	a1,s3
    80005274:	00092503          	lw	a0,0(s2)
    80005278:	ffffe097          	auipc	ra,0xffffe
    8000527c:	458080e7          	jalr	1112(ra) # 800036d0 <ialloc>
    80005280:	84aa                	mv	s1,a0
    80005282:	c529                	beqz	a0,800052cc <create+0xee>
  ilock(ip);
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	5e4080e7          	jalr	1508(ra) # 80003868 <ilock>
  ip->major = major;
    8000528c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005290:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005294:	4785                	li	a5,1
    80005296:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	502080e7          	jalr	1282(ra) # 8000379e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052a4:	2981                	sext.w	s3,s3
    800052a6:	4785                	li	a5,1
    800052a8:	02f98a63          	beq	s3,a5,800052dc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ac:	40d0                	lw	a2,4(s1)
    800052ae:	fb040593          	addi	a1,s0,-80
    800052b2:	854a                	mv	a0,s2
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	ca6080e7          	jalr	-858(ra) # 80003f5a <dirlink>
    800052bc:	06054b63          	bltz	a0,80005332 <create+0x154>
  iunlockput(dp);
    800052c0:	854a                	mv	a0,s2
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	808080e7          	jalr	-2040(ra) # 80003aca <iunlockput>
  return ip;
    800052ca:	b759                	j	80005250 <create+0x72>
    panic("create: ialloc");
    800052cc:	00003517          	auipc	a0,0x3
    800052d0:	46c50513          	addi	a0,a0,1132 # 80008738 <syscalls+0x2b0>
    800052d4:	ffffb097          	auipc	ra,0xffffb
    800052d8:	274080e7          	jalr	628(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800052dc:	04a95783          	lhu	a5,74(s2)
    800052e0:	2785                	addiw	a5,a5,1
    800052e2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052e6:	854a                	mv	a0,s2
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	4b6080e7          	jalr	1206(ra) # 8000379e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052f0:	40d0                	lw	a2,4(s1)
    800052f2:	00003597          	auipc	a1,0x3
    800052f6:	45658593          	addi	a1,a1,1110 # 80008748 <syscalls+0x2c0>
    800052fa:	8526                	mv	a0,s1
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	c5e080e7          	jalr	-930(ra) # 80003f5a <dirlink>
    80005304:	00054f63          	bltz	a0,80005322 <create+0x144>
    80005308:	00492603          	lw	a2,4(s2)
    8000530c:	00003597          	auipc	a1,0x3
    80005310:	44458593          	addi	a1,a1,1092 # 80008750 <syscalls+0x2c8>
    80005314:	8526                	mv	a0,s1
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	c44080e7          	jalr	-956(ra) # 80003f5a <dirlink>
    8000531e:	f80557e3          	bgez	a0,800052ac <create+0xce>
      panic("create dots");
    80005322:	00003517          	auipc	a0,0x3
    80005326:	43650513          	addi	a0,a0,1078 # 80008758 <syscalls+0x2d0>
    8000532a:	ffffb097          	auipc	ra,0xffffb
    8000532e:	21e080e7          	jalr	542(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005332:	00003517          	auipc	a0,0x3
    80005336:	43650513          	addi	a0,a0,1078 # 80008768 <syscalls+0x2e0>
    8000533a:	ffffb097          	auipc	ra,0xffffb
    8000533e:	20e080e7          	jalr	526(ra) # 80000548 <panic>
    return 0;
    80005342:	84aa                	mv	s1,a0
    80005344:	b731                	j	80005250 <create+0x72>

0000000080005346 <sys_dup>:
{
    80005346:	7179                	addi	sp,sp,-48
    80005348:	f406                	sd	ra,40(sp)
    8000534a:	f022                	sd	s0,32(sp)
    8000534c:	ec26                	sd	s1,24(sp)
    8000534e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005350:	fd840613          	addi	a2,s0,-40
    80005354:	4581                	li	a1,0
    80005356:	4501                	li	a0,0
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	ddc080e7          	jalr	-548(ra) # 80005134 <argfd>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005362:	02054363          	bltz	a0,80005388 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005366:	fd843503          	ld	a0,-40(s0)
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	e32080e7          	jalr	-462(ra) # 8000519c <fdalloc>
    80005372:	84aa                	mv	s1,a0
    return -1;
    80005374:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005376:	00054963          	bltz	a0,80005388 <sys_dup+0x42>
  filedup(f);
    8000537a:	fd843503          	ld	a0,-40(s0)
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	32a080e7          	jalr	810(ra) # 800046a8 <filedup>
  return fd;
    80005386:	87a6                	mv	a5,s1
}
    80005388:	853e                	mv	a0,a5
    8000538a:	70a2                	ld	ra,40(sp)
    8000538c:	7402                	ld	s0,32(sp)
    8000538e:	64e2                	ld	s1,24(sp)
    80005390:	6145                	addi	sp,sp,48
    80005392:	8082                	ret

0000000080005394 <sys_read>:
{
    80005394:	7179                	addi	sp,sp,-48
    80005396:	f406                	sd	ra,40(sp)
    80005398:	f022                	sd	s0,32(sp)
    8000539a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539c:	fe840613          	addi	a2,s0,-24
    800053a0:	4581                	li	a1,0
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	d90080e7          	jalr	-624(ra) # 80005134 <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ae:	04054163          	bltz	a0,800053f0 <sys_read+0x5c>
    800053b2:	fe440593          	addi	a1,s0,-28
    800053b6:	4509                	li	a0,2
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	93e080e7          	jalr	-1730(ra) # 80002cf6 <argint>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c2:	02054763          	bltz	a0,800053f0 <sys_read+0x5c>
    800053c6:	fd840593          	addi	a1,s0,-40
    800053ca:	4505                	li	a0,1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	94c080e7          	jalr	-1716(ra) # 80002d18 <argaddr>
    return -1;
    800053d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d6:	00054d63          	bltz	a0,800053f0 <sys_read+0x5c>
  return fileread(f, p, n);
    800053da:	fe442603          	lw	a2,-28(s0)
    800053de:	fd843583          	ld	a1,-40(s0)
    800053e2:	fe843503          	ld	a0,-24(s0)
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	44e080e7          	jalr	1102(ra) # 80004834 <fileread>
    800053ee:	87aa                	mv	a5,a0
}
    800053f0:	853e                	mv	a0,a5
    800053f2:	70a2                	ld	ra,40(sp)
    800053f4:	7402                	ld	s0,32(sp)
    800053f6:	6145                	addi	sp,sp,48
    800053f8:	8082                	ret

00000000800053fa <sys_write>:
{
    800053fa:	7179                	addi	sp,sp,-48
    800053fc:	f406                	sd	ra,40(sp)
    800053fe:	f022                	sd	s0,32(sp)
    80005400:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005402:	fe840613          	addi	a2,s0,-24
    80005406:	4581                	li	a1,0
    80005408:	4501                	li	a0,0
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	d2a080e7          	jalr	-726(ra) # 80005134 <argfd>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005414:	04054163          	bltz	a0,80005456 <sys_write+0x5c>
    80005418:	fe440593          	addi	a1,s0,-28
    8000541c:	4509                	li	a0,2
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	8d8080e7          	jalr	-1832(ra) # 80002cf6 <argint>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005428:	02054763          	bltz	a0,80005456 <sys_write+0x5c>
    8000542c:	fd840593          	addi	a1,s0,-40
    80005430:	4505                	li	a0,1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	8e6080e7          	jalr	-1818(ra) # 80002d18 <argaddr>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543c:	00054d63          	bltz	a0,80005456 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005440:	fe442603          	lw	a2,-28(s0)
    80005444:	fd843583          	ld	a1,-40(s0)
    80005448:	fe843503          	ld	a0,-24(s0)
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	4aa080e7          	jalr	1194(ra) # 800048f6 <filewrite>
    80005454:	87aa                	mv	a5,a0
}
    80005456:	853e                	mv	a0,a5
    80005458:	70a2                	ld	ra,40(sp)
    8000545a:	7402                	ld	s0,32(sp)
    8000545c:	6145                	addi	sp,sp,48
    8000545e:	8082                	ret

0000000080005460 <sys_close>:
{
    80005460:	1101                	addi	sp,sp,-32
    80005462:	ec06                	sd	ra,24(sp)
    80005464:	e822                	sd	s0,16(sp)
    80005466:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005468:	fe040613          	addi	a2,s0,-32
    8000546c:	fec40593          	addi	a1,s0,-20
    80005470:	4501                	li	a0,0
    80005472:	00000097          	auipc	ra,0x0
    80005476:	cc2080e7          	jalr	-830(ra) # 80005134 <argfd>
    return -1;
    8000547a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000547c:	02054463          	bltz	a0,800054a4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	6f8080e7          	jalr	1784(ra) # 80001b78 <myproc>
    80005488:	fec42783          	lw	a5,-20(s0)
    8000548c:	07e9                	addi	a5,a5,26
    8000548e:	078e                	slli	a5,a5,0x3
    80005490:	97aa                	add	a5,a5,a0
    80005492:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005496:	fe043503          	ld	a0,-32(s0)
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	260080e7          	jalr	608(ra) # 800046fa <fileclose>
  return 0;
    800054a2:	4781                	li	a5,0
}
    800054a4:	853e                	mv	a0,a5
    800054a6:	60e2                	ld	ra,24(sp)
    800054a8:	6442                	ld	s0,16(sp)
    800054aa:	6105                	addi	sp,sp,32
    800054ac:	8082                	ret

00000000800054ae <sys_fstat>:
{
    800054ae:	1101                	addi	sp,sp,-32
    800054b0:	ec06                	sd	ra,24(sp)
    800054b2:	e822                	sd	s0,16(sp)
    800054b4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b6:	fe840613          	addi	a2,s0,-24
    800054ba:	4581                	li	a1,0
    800054bc:	4501                	li	a0,0
    800054be:	00000097          	auipc	ra,0x0
    800054c2:	c76080e7          	jalr	-906(ra) # 80005134 <argfd>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c8:	02054563          	bltz	a0,800054f2 <sys_fstat+0x44>
    800054cc:	fe040593          	addi	a1,s0,-32
    800054d0:	4505                	li	a0,1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	846080e7          	jalr	-1978(ra) # 80002d18 <argaddr>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054dc:	00054b63          	bltz	a0,800054f2 <sys_fstat+0x44>
  return filestat(f, st);
    800054e0:	fe043583          	ld	a1,-32(s0)
    800054e4:	fe843503          	ld	a0,-24(s0)
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	2da080e7          	jalr	730(ra) # 800047c2 <filestat>
    800054f0:	87aa                	mv	a5,a0
}
    800054f2:	853e                	mv	a0,a5
    800054f4:	60e2                	ld	ra,24(sp)
    800054f6:	6442                	ld	s0,16(sp)
    800054f8:	6105                	addi	sp,sp,32
    800054fa:	8082                	ret

00000000800054fc <sys_link>:
{
    800054fc:	7169                	addi	sp,sp,-304
    800054fe:	f606                	sd	ra,296(sp)
    80005500:	f222                	sd	s0,288(sp)
    80005502:	ee26                	sd	s1,280(sp)
    80005504:	ea4a                	sd	s2,272(sp)
    80005506:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005508:	08000613          	li	a2,128
    8000550c:	ed040593          	addi	a1,s0,-304
    80005510:	4501                	li	a0,0
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	828080e7          	jalr	-2008(ra) # 80002d3a <argstr>
    return -1;
    8000551a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551c:	10054e63          	bltz	a0,80005638 <sys_link+0x13c>
    80005520:	08000613          	li	a2,128
    80005524:	f5040593          	addi	a1,s0,-176
    80005528:	4505                	li	a0,1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	810080e7          	jalr	-2032(ra) # 80002d3a <argstr>
    return -1;
    80005532:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005534:	10054263          	bltz	a0,80005638 <sys_link+0x13c>
  begin_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	cf0080e7          	jalr	-784(ra) # 80004228 <begin_op>
  if((ip = namei(old)) == 0){
    80005540:	ed040513          	addi	a0,s0,-304
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	ad8080e7          	jalr	-1320(ra) # 8000401c <namei>
    8000554c:	84aa                	mv	s1,a0
    8000554e:	c551                	beqz	a0,800055da <sys_link+0xde>
  ilock(ip);
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	318080e7          	jalr	792(ra) # 80003868 <ilock>
  if(ip->type == T_DIR){
    80005558:	04449703          	lh	a4,68(s1)
    8000555c:	4785                	li	a5,1
    8000555e:	08f70463          	beq	a4,a5,800055e6 <sys_link+0xea>
  ip->nlink++;
    80005562:	04a4d783          	lhu	a5,74(s1)
    80005566:	2785                	addiw	a5,a5,1
    80005568:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	230080e7          	jalr	560(ra) # 8000379e <iupdate>
  iunlock(ip);
    80005576:	8526                	mv	a0,s1
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	3b2080e7          	jalr	946(ra) # 8000392a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005580:	fd040593          	addi	a1,s0,-48
    80005584:	f5040513          	addi	a0,s0,-176
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	ab2080e7          	jalr	-1358(ra) # 8000403a <nameiparent>
    80005590:	892a                	mv	s2,a0
    80005592:	c935                	beqz	a0,80005606 <sys_link+0x10a>
  ilock(dp);
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	2d4080e7          	jalr	724(ra) # 80003868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000559c:	00092703          	lw	a4,0(s2)
    800055a0:	409c                	lw	a5,0(s1)
    800055a2:	04f71d63          	bne	a4,a5,800055fc <sys_link+0x100>
    800055a6:	40d0                	lw	a2,4(s1)
    800055a8:	fd040593          	addi	a1,s0,-48
    800055ac:	854a                	mv	a0,s2
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	9ac080e7          	jalr	-1620(ra) # 80003f5a <dirlink>
    800055b6:	04054363          	bltz	a0,800055fc <sys_link+0x100>
  iunlockput(dp);
    800055ba:	854a                	mv	a0,s2
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	50e080e7          	jalr	1294(ra) # 80003aca <iunlockput>
  iput(ip);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	45c080e7          	jalr	1116(ra) # 80003a22 <iput>
  end_op();
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	cda080e7          	jalr	-806(ra) # 800042a8 <end_op>
  return 0;
    800055d6:	4781                	li	a5,0
    800055d8:	a085                	j	80005638 <sys_link+0x13c>
    end_op();
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	cce080e7          	jalr	-818(ra) # 800042a8 <end_op>
    return -1;
    800055e2:	57fd                	li	a5,-1
    800055e4:	a891                	j	80005638 <sys_link+0x13c>
    iunlockput(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	4e2080e7          	jalr	1250(ra) # 80003aca <iunlockput>
    end_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	cb8080e7          	jalr	-840(ra) # 800042a8 <end_op>
    return -1;
    800055f8:	57fd                	li	a5,-1
    800055fa:	a83d                	j	80005638 <sys_link+0x13c>
    iunlockput(dp);
    800055fc:	854a                	mv	a0,s2
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	4cc080e7          	jalr	1228(ra) # 80003aca <iunlockput>
  ilock(ip);
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	260080e7          	jalr	608(ra) # 80003868 <ilock>
  ip->nlink--;
    80005610:	04a4d783          	lhu	a5,74(s1)
    80005614:	37fd                	addiw	a5,a5,-1
    80005616:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	182080e7          	jalr	386(ra) # 8000379e <iupdate>
  iunlockput(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	4a4080e7          	jalr	1188(ra) # 80003aca <iunlockput>
  end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	c7a080e7          	jalr	-902(ra) # 800042a8 <end_op>
  return -1;
    80005636:	57fd                	li	a5,-1
}
    80005638:	853e                	mv	a0,a5
    8000563a:	70b2                	ld	ra,296(sp)
    8000563c:	7412                	ld	s0,288(sp)
    8000563e:	64f2                	ld	s1,280(sp)
    80005640:	6952                	ld	s2,272(sp)
    80005642:	6155                	addi	sp,sp,304
    80005644:	8082                	ret

0000000080005646 <sys_unlink>:
{
    80005646:	7151                	addi	sp,sp,-240
    80005648:	f586                	sd	ra,232(sp)
    8000564a:	f1a2                	sd	s0,224(sp)
    8000564c:	eda6                	sd	s1,216(sp)
    8000564e:	e9ca                	sd	s2,208(sp)
    80005650:	e5ce                	sd	s3,200(sp)
    80005652:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005654:	08000613          	li	a2,128
    80005658:	f3040593          	addi	a1,s0,-208
    8000565c:	4501                	li	a0,0
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	6dc080e7          	jalr	1756(ra) # 80002d3a <argstr>
    80005666:	18054163          	bltz	a0,800057e8 <sys_unlink+0x1a2>
  begin_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	bbe080e7          	jalr	-1090(ra) # 80004228 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005672:	fb040593          	addi	a1,s0,-80
    80005676:	f3040513          	addi	a0,s0,-208
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	9c0080e7          	jalr	-1600(ra) # 8000403a <nameiparent>
    80005682:	84aa                	mv	s1,a0
    80005684:	c979                	beqz	a0,8000575a <sys_unlink+0x114>
  ilock(dp);
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	1e2080e7          	jalr	482(ra) # 80003868 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000568e:	00003597          	auipc	a1,0x3
    80005692:	0ba58593          	addi	a1,a1,186 # 80008748 <syscalls+0x2c0>
    80005696:	fb040513          	addi	a0,s0,-80
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	696080e7          	jalr	1686(ra) # 80003d30 <namecmp>
    800056a2:	14050a63          	beqz	a0,800057f6 <sys_unlink+0x1b0>
    800056a6:	00003597          	auipc	a1,0x3
    800056aa:	0aa58593          	addi	a1,a1,170 # 80008750 <syscalls+0x2c8>
    800056ae:	fb040513          	addi	a0,s0,-80
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	67e080e7          	jalr	1662(ra) # 80003d30 <namecmp>
    800056ba:	12050e63          	beqz	a0,800057f6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056be:	f2c40613          	addi	a2,s0,-212
    800056c2:	fb040593          	addi	a1,s0,-80
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	682080e7          	jalr	1666(ra) # 80003d4a <dirlookup>
    800056d0:	892a                	mv	s2,a0
    800056d2:	12050263          	beqz	a0,800057f6 <sys_unlink+0x1b0>
  ilock(ip);
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	192080e7          	jalr	402(ra) # 80003868 <ilock>
  if(ip->nlink < 1)
    800056de:	04a91783          	lh	a5,74(s2)
    800056e2:	08f05263          	blez	a5,80005766 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056e6:	04491703          	lh	a4,68(s2)
    800056ea:	4785                	li	a5,1
    800056ec:	08f70563          	beq	a4,a5,80005776 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056f0:	4641                	li	a2,16
    800056f2:	4581                	li	a1,0
    800056f4:	fc040513          	addi	a0,s0,-64
    800056f8:	ffffb097          	auipc	ra,0xffffb
    800056fc:	75e080e7          	jalr	1886(ra) # 80000e56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005700:	4741                	li	a4,16
    80005702:	f2c42683          	lw	a3,-212(s0)
    80005706:	fc040613          	addi	a2,s0,-64
    8000570a:	4581                	li	a1,0
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	506080e7          	jalr	1286(ra) # 80003c14 <writei>
    80005716:	47c1                	li	a5,16
    80005718:	0af51563          	bne	a0,a5,800057c2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000571c:	04491703          	lh	a4,68(s2)
    80005720:	4785                	li	a5,1
    80005722:	0af70863          	beq	a4,a5,800057d2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	3a2080e7          	jalr	930(ra) # 80003aca <iunlockput>
  ip->nlink--;
    80005730:	04a95783          	lhu	a5,74(s2)
    80005734:	37fd                	addiw	a5,a5,-1
    80005736:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000573a:	854a                	mv	a0,s2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	062080e7          	jalr	98(ra) # 8000379e <iupdate>
  iunlockput(ip);
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	384080e7          	jalr	900(ra) # 80003aca <iunlockput>
  end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	b5a080e7          	jalr	-1190(ra) # 800042a8 <end_op>
  return 0;
    80005756:	4501                	li	a0,0
    80005758:	a84d                	j	8000580a <sys_unlink+0x1c4>
    end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	b4e080e7          	jalr	-1202(ra) # 800042a8 <end_op>
    return -1;
    80005762:	557d                	li	a0,-1
    80005764:	a05d                	j	8000580a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005766:	00003517          	auipc	a0,0x3
    8000576a:	01250513          	addi	a0,a0,18 # 80008778 <syscalls+0x2f0>
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	dda080e7          	jalr	-550(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005776:	04c92703          	lw	a4,76(s2)
    8000577a:	02000793          	li	a5,32
    8000577e:	f6e7f9e3          	bgeu	a5,a4,800056f0 <sys_unlink+0xaa>
    80005782:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005786:	4741                	li	a4,16
    80005788:	86ce                	mv	a3,s3
    8000578a:	f1840613          	addi	a2,s0,-232
    8000578e:	4581                	li	a1,0
    80005790:	854a                	mv	a0,s2
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	38a080e7          	jalr	906(ra) # 80003b1c <readi>
    8000579a:	47c1                	li	a5,16
    8000579c:	00f51b63          	bne	a0,a5,800057b2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057a0:	f1845783          	lhu	a5,-232(s0)
    800057a4:	e7a1                	bnez	a5,800057ec <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a6:	29c1                	addiw	s3,s3,16
    800057a8:	04c92783          	lw	a5,76(s2)
    800057ac:	fcf9ede3          	bltu	s3,a5,80005786 <sys_unlink+0x140>
    800057b0:	b781                	j	800056f0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057b2:	00003517          	auipc	a0,0x3
    800057b6:	fde50513          	addi	a0,a0,-34 # 80008790 <syscalls+0x308>
    800057ba:	ffffb097          	auipc	ra,0xffffb
    800057be:	d8e080e7          	jalr	-626(ra) # 80000548 <panic>
    panic("unlink: writei");
    800057c2:	00003517          	auipc	a0,0x3
    800057c6:	fe650513          	addi	a0,a0,-26 # 800087a8 <syscalls+0x320>
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	d7e080e7          	jalr	-642(ra) # 80000548 <panic>
    dp->nlink--;
    800057d2:	04a4d783          	lhu	a5,74(s1)
    800057d6:	37fd                	addiw	a5,a5,-1
    800057d8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	fc0080e7          	jalr	-64(ra) # 8000379e <iupdate>
    800057e6:	b781                	j	80005726 <sys_unlink+0xe0>
    return -1;
    800057e8:	557d                	li	a0,-1
    800057ea:	a005                	j	8000580a <sys_unlink+0x1c4>
    iunlockput(ip);
    800057ec:	854a                	mv	a0,s2
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	2dc080e7          	jalr	732(ra) # 80003aca <iunlockput>
  iunlockput(dp);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	2d2080e7          	jalr	722(ra) # 80003aca <iunlockput>
  end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	aa8080e7          	jalr	-1368(ra) # 800042a8 <end_op>
  return -1;
    80005808:	557d                	li	a0,-1
}
    8000580a:	70ae                	ld	ra,232(sp)
    8000580c:	740e                	ld	s0,224(sp)
    8000580e:	64ee                	ld	s1,216(sp)
    80005810:	694e                	ld	s2,208(sp)
    80005812:	69ae                	ld	s3,200(sp)
    80005814:	616d                	addi	sp,sp,240
    80005816:	8082                	ret

0000000080005818 <sys_open>:

uint64
sys_open(void)
{
    80005818:	7131                	addi	sp,sp,-192
    8000581a:	fd06                	sd	ra,184(sp)
    8000581c:	f922                	sd	s0,176(sp)
    8000581e:	f526                	sd	s1,168(sp)
    80005820:	f14a                	sd	s2,160(sp)
    80005822:	ed4e                	sd	s3,152(sp)
    80005824:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005826:	08000613          	li	a2,128
    8000582a:	f5040593          	addi	a1,s0,-176
    8000582e:	4501                	li	a0,0
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	50a080e7          	jalr	1290(ra) # 80002d3a <argstr>
    return -1;
    80005838:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000583a:	0c054163          	bltz	a0,800058fc <sys_open+0xe4>
    8000583e:	f4c40593          	addi	a1,s0,-180
    80005842:	4505                	li	a0,1
    80005844:	ffffd097          	auipc	ra,0xffffd
    80005848:	4b2080e7          	jalr	1202(ra) # 80002cf6 <argint>
    8000584c:	0a054863          	bltz	a0,800058fc <sys_open+0xe4>

  begin_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	9d8080e7          	jalr	-1576(ra) # 80004228 <begin_op>

  if(omode & O_CREATE){
    80005858:	f4c42783          	lw	a5,-180(s0)
    8000585c:	2007f793          	andi	a5,a5,512
    80005860:	cbdd                	beqz	a5,80005916 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005862:	4681                	li	a3,0
    80005864:	4601                	li	a2,0
    80005866:	4589                	li	a1,2
    80005868:	f5040513          	addi	a0,s0,-176
    8000586c:	00000097          	auipc	ra,0x0
    80005870:	972080e7          	jalr	-1678(ra) # 800051de <create>
    80005874:	892a                	mv	s2,a0
    if(ip == 0){
    80005876:	c959                	beqz	a0,8000590c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005878:	04491703          	lh	a4,68(s2)
    8000587c:	478d                	li	a5,3
    8000587e:	00f71763          	bne	a4,a5,8000588c <sys_open+0x74>
    80005882:	04695703          	lhu	a4,70(s2)
    80005886:	47a5                	li	a5,9
    80005888:	0ce7ec63          	bltu	a5,a4,80005960 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	db2080e7          	jalr	-590(ra) # 8000463e <filealloc>
    80005894:	89aa                	mv	s3,a0
    80005896:	10050263          	beqz	a0,8000599a <sys_open+0x182>
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	902080e7          	jalr	-1790(ra) # 8000519c <fdalloc>
    800058a2:	84aa                	mv	s1,a0
    800058a4:	0e054663          	bltz	a0,80005990 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058a8:	04491703          	lh	a4,68(s2)
    800058ac:	478d                	li	a5,3
    800058ae:	0cf70463          	beq	a4,a5,80005976 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058b2:	4789                	li	a5,2
    800058b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058bc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058c0:	f4c42783          	lw	a5,-180(s0)
    800058c4:	0017c713          	xori	a4,a5,1
    800058c8:	8b05                	andi	a4,a4,1
    800058ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058ce:	0037f713          	andi	a4,a5,3
    800058d2:	00e03733          	snez	a4,a4
    800058d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058da:	4007f793          	andi	a5,a5,1024
    800058de:	c791                	beqz	a5,800058ea <sys_open+0xd2>
    800058e0:	04491703          	lh	a4,68(s2)
    800058e4:	4789                	li	a5,2
    800058e6:	08f70f63          	beq	a4,a5,80005984 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058ea:	854a                	mv	a0,s2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	03e080e7          	jalr	62(ra) # 8000392a <iunlock>
  end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9b4080e7          	jalr	-1612(ra) # 800042a8 <end_op>

  return fd;
}
    800058fc:	8526                	mv	a0,s1
    800058fe:	70ea                	ld	ra,184(sp)
    80005900:	744a                	ld	s0,176(sp)
    80005902:	74aa                	ld	s1,168(sp)
    80005904:	790a                	ld	s2,160(sp)
    80005906:	69ea                	ld	s3,152(sp)
    80005908:	6129                	addi	sp,sp,192
    8000590a:	8082                	ret
      end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	99c080e7          	jalr	-1636(ra) # 800042a8 <end_op>
      return -1;
    80005914:	b7e5                	j	800058fc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005916:	f5040513          	addi	a0,s0,-176
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	702080e7          	jalr	1794(ra) # 8000401c <namei>
    80005922:	892a                	mv	s2,a0
    80005924:	c905                	beqz	a0,80005954 <sys_open+0x13c>
    ilock(ip);
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	f42080e7          	jalr	-190(ra) # 80003868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000592e:	04491703          	lh	a4,68(s2)
    80005932:	4785                	li	a5,1
    80005934:	f4f712e3          	bne	a4,a5,80005878 <sys_open+0x60>
    80005938:	f4c42783          	lw	a5,-180(s0)
    8000593c:	dba1                	beqz	a5,8000588c <sys_open+0x74>
      iunlockput(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	18a080e7          	jalr	394(ra) # 80003aca <iunlockput>
      end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	960080e7          	jalr	-1696(ra) # 800042a8 <end_op>
      return -1;
    80005950:	54fd                	li	s1,-1
    80005952:	b76d                	j	800058fc <sys_open+0xe4>
      end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	954080e7          	jalr	-1708(ra) # 800042a8 <end_op>
      return -1;
    8000595c:	54fd                	li	s1,-1
    8000595e:	bf79                	j	800058fc <sys_open+0xe4>
    iunlockput(ip);
    80005960:	854a                	mv	a0,s2
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	168080e7          	jalr	360(ra) # 80003aca <iunlockput>
    end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	93e080e7          	jalr	-1730(ra) # 800042a8 <end_op>
    return -1;
    80005972:	54fd                	li	s1,-1
    80005974:	b761                	j	800058fc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005976:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000597a:	04691783          	lh	a5,70(s2)
    8000597e:	02f99223          	sh	a5,36(s3)
    80005982:	bf2d                	j	800058bc <sys_open+0xa4>
    itrunc(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	ff0080e7          	jalr	-16(ra) # 80003976 <itrunc>
    8000598e:	bfb1                	j	800058ea <sys_open+0xd2>
      fileclose(f);
    80005990:	854e                	mv	a0,s3
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	d68080e7          	jalr	-664(ra) # 800046fa <fileclose>
    iunlockput(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	12e080e7          	jalr	302(ra) # 80003aca <iunlockput>
    end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	904080e7          	jalr	-1788(ra) # 800042a8 <end_op>
    return -1;
    800059ac:	54fd                	li	s1,-1
    800059ae:	b7b9                	j	800058fc <sys_open+0xe4>

00000000800059b0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059b0:	7175                	addi	sp,sp,-144
    800059b2:	e506                	sd	ra,136(sp)
    800059b4:	e122                	sd	s0,128(sp)
    800059b6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	870080e7          	jalr	-1936(ra) # 80004228 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059c0:	08000613          	li	a2,128
    800059c4:	f7040593          	addi	a1,s0,-144
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	370080e7          	jalr	880(ra) # 80002d3a <argstr>
    800059d2:	02054963          	bltz	a0,80005a04 <sys_mkdir+0x54>
    800059d6:	4681                	li	a3,0
    800059d8:	4601                	li	a2,0
    800059da:	4585                	li	a1,1
    800059dc:	f7040513          	addi	a0,s0,-144
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	7fe080e7          	jalr	2046(ra) # 800051de <create>
    800059e8:	cd11                	beqz	a0,80005a04 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	0e0080e7          	jalr	224(ra) # 80003aca <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	8b6080e7          	jalr	-1866(ra) # 800042a8 <end_op>
  return 0;
    800059fa:	4501                	li	a0,0
}
    800059fc:	60aa                	ld	ra,136(sp)
    800059fe:	640a                	ld	s0,128(sp)
    80005a00:	6149                	addi	sp,sp,144
    80005a02:	8082                	ret
    end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	8a4080e7          	jalr	-1884(ra) # 800042a8 <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	b7fd                	j	800059fc <sys_mkdir+0x4c>

0000000080005a10 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a10:	7135                	addi	sp,sp,-160
    80005a12:	ed06                	sd	ra,152(sp)
    80005a14:	e922                	sd	s0,144(sp)
    80005a16:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	810080e7          	jalr	-2032(ra) # 80004228 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a20:	08000613          	li	a2,128
    80005a24:	f7040593          	addi	a1,s0,-144
    80005a28:	4501                	li	a0,0
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	310080e7          	jalr	784(ra) # 80002d3a <argstr>
    80005a32:	04054a63          	bltz	a0,80005a86 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a36:	f6c40593          	addi	a1,s0,-148
    80005a3a:	4505                	li	a0,1
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	2ba080e7          	jalr	698(ra) # 80002cf6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a44:	04054163          	bltz	a0,80005a86 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a48:	f6840593          	addi	a1,s0,-152
    80005a4c:	4509                	li	a0,2
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	2a8080e7          	jalr	680(ra) # 80002cf6 <argint>
     argint(1, &major) < 0 ||
    80005a56:	02054863          	bltz	a0,80005a86 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a5a:	f6841683          	lh	a3,-152(s0)
    80005a5e:	f6c41603          	lh	a2,-148(s0)
    80005a62:	458d                	li	a1,3
    80005a64:	f7040513          	addi	a0,s0,-144
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	776080e7          	jalr	1910(ra) # 800051de <create>
     argint(2, &minor) < 0 ||
    80005a70:	c919                	beqz	a0,80005a86 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	058080e7          	jalr	88(ra) # 80003aca <iunlockput>
  end_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	82e080e7          	jalr	-2002(ra) # 800042a8 <end_op>
  return 0;
    80005a82:	4501                	li	a0,0
    80005a84:	a031                	j	80005a90 <sys_mknod+0x80>
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	822080e7          	jalr	-2014(ra) # 800042a8 <end_op>
    return -1;
    80005a8e:	557d                	li	a0,-1
}
    80005a90:	60ea                	ld	ra,152(sp)
    80005a92:	644a                	ld	s0,144(sp)
    80005a94:	610d                	addi	sp,sp,160
    80005a96:	8082                	ret

0000000080005a98 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a98:	7135                	addi	sp,sp,-160
    80005a9a:	ed06                	sd	ra,152(sp)
    80005a9c:	e922                	sd	s0,144(sp)
    80005a9e:	e526                	sd	s1,136(sp)
    80005aa0:	e14a                	sd	s2,128(sp)
    80005aa2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aa4:	ffffc097          	auipc	ra,0xffffc
    80005aa8:	0d4080e7          	jalr	212(ra) # 80001b78 <myproc>
    80005aac:	892a                	mv	s2,a0
  
  begin_op();
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	77a080e7          	jalr	1914(ra) # 80004228 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ab6:	08000613          	li	a2,128
    80005aba:	f6040593          	addi	a1,s0,-160
    80005abe:	4501                	li	a0,0
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	27a080e7          	jalr	634(ra) # 80002d3a <argstr>
    80005ac8:	04054b63          	bltz	a0,80005b1e <sys_chdir+0x86>
    80005acc:	f6040513          	addi	a0,s0,-160
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	54c080e7          	jalr	1356(ra) # 8000401c <namei>
    80005ad8:	84aa                	mv	s1,a0
    80005ada:	c131                	beqz	a0,80005b1e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	d8c080e7          	jalr	-628(ra) # 80003868 <ilock>
  if(ip->type != T_DIR){
    80005ae4:	04449703          	lh	a4,68(s1)
    80005ae8:	4785                	li	a5,1
    80005aea:	04f71063          	bne	a4,a5,80005b2a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005aee:	8526                	mv	a0,s1
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	e3a080e7          	jalr	-454(ra) # 8000392a <iunlock>
  iput(p->cwd);
    80005af8:	15093503          	ld	a0,336(s2)
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	f26080e7          	jalr	-218(ra) # 80003a22 <iput>
  end_op();
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	7a4080e7          	jalr	1956(ra) # 800042a8 <end_op>
  p->cwd = ip;
    80005b0c:	14993823          	sd	s1,336(s2)
  return 0;
    80005b10:	4501                	li	a0,0
}
    80005b12:	60ea                	ld	ra,152(sp)
    80005b14:	644a                	ld	s0,144(sp)
    80005b16:	64aa                	ld	s1,136(sp)
    80005b18:	690a                	ld	s2,128(sp)
    80005b1a:	610d                	addi	sp,sp,160
    80005b1c:	8082                	ret
    end_op();
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	78a080e7          	jalr	1930(ra) # 800042a8 <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	b7ed                	j	80005b12 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	f9e080e7          	jalr	-98(ra) # 80003aca <iunlockput>
    end_op();
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	774080e7          	jalr	1908(ra) # 800042a8 <end_op>
    return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	bfd1                	j	80005b12 <sys_chdir+0x7a>

0000000080005b40 <sys_exec>:

uint64
sys_exec(void)
{
    80005b40:	7145                	addi	sp,sp,-464
    80005b42:	e786                	sd	ra,456(sp)
    80005b44:	e3a2                	sd	s0,448(sp)
    80005b46:	ff26                	sd	s1,440(sp)
    80005b48:	fb4a                	sd	s2,432(sp)
    80005b4a:	f74e                	sd	s3,424(sp)
    80005b4c:	f352                	sd	s4,416(sp)
    80005b4e:	ef56                	sd	s5,408(sp)
    80005b50:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b52:	08000613          	li	a2,128
    80005b56:	f4040593          	addi	a1,s0,-192
    80005b5a:	4501                	li	a0,0
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	1de080e7          	jalr	478(ra) # 80002d3a <argstr>
    return -1;
    80005b64:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b66:	0c054a63          	bltz	a0,80005c3a <sys_exec+0xfa>
    80005b6a:	e3840593          	addi	a1,s0,-456
    80005b6e:	4505                	li	a0,1
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	1a8080e7          	jalr	424(ra) # 80002d18 <argaddr>
    80005b78:	0c054163          	bltz	a0,80005c3a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b7c:	10000613          	li	a2,256
    80005b80:	4581                	li	a1,0
    80005b82:	e4040513          	addi	a0,s0,-448
    80005b86:	ffffb097          	auipc	ra,0xffffb
    80005b8a:	2d0080e7          	jalr	720(ra) # 80000e56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b8e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b92:	89a6                	mv	s3,s1
    80005b94:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b96:	02000a13          	li	s4,32
    80005b9a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b9e:	00391513          	slli	a0,s2,0x3
    80005ba2:	e3040593          	addi	a1,s0,-464
    80005ba6:	e3843783          	ld	a5,-456(s0)
    80005baa:	953e                	add	a0,a0,a5
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	0b0080e7          	jalr	176(ra) # 80002c5c <fetchaddr>
    80005bb4:	02054a63          	bltz	a0,80005be8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bb8:	e3043783          	ld	a5,-464(s0)
    80005bbc:	c3b9                	beqz	a5,80005c02 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	06a080e7          	jalr	106(ra) # 80000c28 <kalloc>
    80005bc6:	85aa                	mv	a1,a0
    80005bc8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bcc:	cd11                	beqz	a0,80005be8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bce:	6605                	lui	a2,0x1
    80005bd0:	e3043503          	ld	a0,-464(s0)
    80005bd4:	ffffd097          	auipc	ra,0xffffd
    80005bd8:	0da080e7          	jalr	218(ra) # 80002cae <fetchstr>
    80005bdc:	00054663          	bltz	a0,80005be8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005be0:	0905                	addi	s2,s2,1
    80005be2:	09a1                	addi	s3,s3,8
    80005be4:	fb491be3          	bne	s2,s4,80005b9a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be8:	10048913          	addi	s2,s1,256
    80005bec:	6088                	ld	a0,0(s1)
    80005bee:	c529                	beqz	a0,80005c38 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	eb0080e7          	jalr	-336(ra) # 80000aa0 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf8:	04a1                	addi	s1,s1,8
    80005bfa:	ff2499e3          	bne	s1,s2,80005bec <sys_exec+0xac>
  return -1;
    80005bfe:	597d                	li	s2,-1
    80005c00:	a82d                	j	80005c3a <sys_exec+0xfa>
      argv[i] = 0;
    80005c02:	0a8e                	slli	s5,s5,0x3
    80005c04:	fc040793          	addi	a5,s0,-64
    80005c08:	9abe                	add	s5,s5,a5
    80005c0a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c0e:	e4040593          	addi	a1,s0,-448
    80005c12:	f4040513          	addi	a0,s0,-192
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	194080e7          	jalr	404(ra) # 80004daa <exec>
    80005c1e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c20:	10048993          	addi	s3,s1,256
    80005c24:	6088                	ld	a0,0(s1)
    80005c26:	c911                	beqz	a0,80005c3a <sys_exec+0xfa>
    kfree(argv[i]);
    80005c28:	ffffb097          	auipc	ra,0xffffb
    80005c2c:	e78080e7          	jalr	-392(ra) # 80000aa0 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c30:	04a1                	addi	s1,s1,8
    80005c32:	ff3499e3          	bne	s1,s3,80005c24 <sys_exec+0xe4>
    80005c36:	a011                	j	80005c3a <sys_exec+0xfa>
  return -1;
    80005c38:	597d                	li	s2,-1
}
    80005c3a:	854a                	mv	a0,s2
    80005c3c:	60be                	ld	ra,456(sp)
    80005c3e:	641e                	ld	s0,448(sp)
    80005c40:	74fa                	ld	s1,440(sp)
    80005c42:	795a                	ld	s2,432(sp)
    80005c44:	79ba                	ld	s3,424(sp)
    80005c46:	7a1a                	ld	s4,416(sp)
    80005c48:	6afa                	ld	s5,408(sp)
    80005c4a:	6179                	addi	sp,sp,464
    80005c4c:	8082                	ret

0000000080005c4e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c4e:	7139                	addi	sp,sp,-64
    80005c50:	fc06                	sd	ra,56(sp)
    80005c52:	f822                	sd	s0,48(sp)
    80005c54:	f426                	sd	s1,40(sp)
    80005c56:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	f20080e7          	jalr	-224(ra) # 80001b78 <myproc>
    80005c60:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c62:	fd840593          	addi	a1,s0,-40
    80005c66:	4501                	li	a0,0
    80005c68:	ffffd097          	auipc	ra,0xffffd
    80005c6c:	0b0080e7          	jalr	176(ra) # 80002d18 <argaddr>
    return -1;
    80005c70:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c72:	0e054063          	bltz	a0,80005d52 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c76:	fc840593          	addi	a1,s0,-56
    80005c7a:	fd040513          	addi	a0,s0,-48
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	dd2080e7          	jalr	-558(ra) # 80004a50 <pipealloc>
    return -1;
    80005c86:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c88:	0c054563          	bltz	a0,80005d52 <sys_pipe+0x104>
  fd0 = -1;
    80005c8c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c90:	fd043503          	ld	a0,-48(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	508080e7          	jalr	1288(ra) # 8000519c <fdalloc>
    80005c9c:	fca42223          	sw	a0,-60(s0)
    80005ca0:	08054c63          	bltz	a0,80005d38 <sys_pipe+0xea>
    80005ca4:	fc843503          	ld	a0,-56(s0)
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	4f4080e7          	jalr	1268(ra) # 8000519c <fdalloc>
    80005cb0:	fca42023          	sw	a0,-64(s0)
    80005cb4:	06054863          	bltz	a0,80005d24 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cb8:	4691                	li	a3,4
    80005cba:	fc440613          	addi	a2,s0,-60
    80005cbe:	fd843583          	ld	a1,-40(s0)
    80005cc2:	68a8                	ld	a0,80(s1)
    80005cc4:	ffffc097          	auipc	ra,0xffffc
    80005cc8:	b44080e7          	jalr	-1212(ra) # 80001808 <copyout>
    80005ccc:	02054063          	bltz	a0,80005cec <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cd0:	4691                	li	a3,4
    80005cd2:	fc040613          	addi	a2,s0,-64
    80005cd6:	fd843583          	ld	a1,-40(s0)
    80005cda:	0591                	addi	a1,a1,4
    80005cdc:	68a8                	ld	a0,80(s1)
    80005cde:	ffffc097          	auipc	ra,0xffffc
    80005ce2:	b2a080e7          	jalr	-1238(ra) # 80001808 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ce6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ce8:	06055563          	bgez	a0,80005d52 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cec:	fc442783          	lw	a5,-60(s0)
    80005cf0:	07e9                	addi	a5,a5,26
    80005cf2:	078e                	slli	a5,a5,0x3
    80005cf4:	97a6                	add	a5,a5,s1
    80005cf6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cfa:	fc042503          	lw	a0,-64(s0)
    80005cfe:	0569                	addi	a0,a0,26
    80005d00:	050e                	slli	a0,a0,0x3
    80005d02:	9526                	add	a0,a0,s1
    80005d04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d08:	fd043503          	ld	a0,-48(s0)
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	9ee080e7          	jalr	-1554(ra) # 800046fa <fileclose>
    fileclose(wf);
    80005d14:	fc843503          	ld	a0,-56(s0)
    80005d18:	fffff097          	auipc	ra,0xfffff
    80005d1c:	9e2080e7          	jalr	-1566(ra) # 800046fa <fileclose>
    return -1;
    80005d20:	57fd                	li	a5,-1
    80005d22:	a805                	j	80005d52 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d24:	fc442783          	lw	a5,-60(s0)
    80005d28:	0007c863          	bltz	a5,80005d38 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d2c:	01a78513          	addi	a0,a5,26
    80005d30:	050e                	slli	a0,a0,0x3
    80005d32:	9526                	add	a0,a0,s1
    80005d34:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d38:	fd043503          	ld	a0,-48(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	9be080e7          	jalr	-1602(ra) # 800046fa <fileclose>
    fileclose(wf);
    80005d44:	fc843503          	ld	a0,-56(s0)
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	9b2080e7          	jalr	-1614(ra) # 800046fa <fileclose>
    return -1;
    80005d50:	57fd                	li	a5,-1
}
    80005d52:	853e                	mv	a0,a5
    80005d54:	70e2                	ld	ra,56(sp)
    80005d56:	7442                	ld	s0,48(sp)
    80005d58:	74a2                	ld	s1,40(sp)
    80005d5a:	6121                	addi	sp,sp,64
    80005d5c:	8082                	ret
	...

0000000080005d60 <kernelvec>:
    80005d60:	7111                	addi	sp,sp,-256
    80005d62:	e006                	sd	ra,0(sp)
    80005d64:	e40a                	sd	sp,8(sp)
    80005d66:	e80e                	sd	gp,16(sp)
    80005d68:	ec12                	sd	tp,24(sp)
    80005d6a:	f016                	sd	t0,32(sp)
    80005d6c:	f41a                	sd	t1,40(sp)
    80005d6e:	f81e                	sd	t2,48(sp)
    80005d70:	fc22                	sd	s0,56(sp)
    80005d72:	e0a6                	sd	s1,64(sp)
    80005d74:	e4aa                	sd	a0,72(sp)
    80005d76:	e8ae                	sd	a1,80(sp)
    80005d78:	ecb2                	sd	a2,88(sp)
    80005d7a:	f0b6                	sd	a3,96(sp)
    80005d7c:	f4ba                	sd	a4,104(sp)
    80005d7e:	f8be                	sd	a5,112(sp)
    80005d80:	fcc2                	sd	a6,120(sp)
    80005d82:	e146                	sd	a7,128(sp)
    80005d84:	e54a                	sd	s2,136(sp)
    80005d86:	e94e                	sd	s3,144(sp)
    80005d88:	ed52                	sd	s4,152(sp)
    80005d8a:	f156                	sd	s5,160(sp)
    80005d8c:	f55a                	sd	s6,168(sp)
    80005d8e:	f95e                	sd	s7,176(sp)
    80005d90:	fd62                	sd	s8,184(sp)
    80005d92:	e1e6                	sd	s9,192(sp)
    80005d94:	e5ea                	sd	s10,200(sp)
    80005d96:	e9ee                	sd	s11,208(sp)
    80005d98:	edf2                	sd	t3,216(sp)
    80005d9a:	f1f6                	sd	t4,224(sp)
    80005d9c:	f5fa                	sd	t5,232(sp)
    80005d9e:	f9fe                	sd	t6,240(sp)
    80005da0:	d89fc0ef          	jal	ra,80002b28 <kerneltrap>
    80005da4:	6082                	ld	ra,0(sp)
    80005da6:	6122                	ld	sp,8(sp)
    80005da8:	61c2                	ld	gp,16(sp)
    80005daa:	7282                	ld	t0,32(sp)
    80005dac:	7322                	ld	t1,40(sp)
    80005dae:	73c2                	ld	t2,48(sp)
    80005db0:	7462                	ld	s0,56(sp)
    80005db2:	6486                	ld	s1,64(sp)
    80005db4:	6526                	ld	a0,72(sp)
    80005db6:	65c6                	ld	a1,80(sp)
    80005db8:	6666                	ld	a2,88(sp)
    80005dba:	7686                	ld	a3,96(sp)
    80005dbc:	7726                	ld	a4,104(sp)
    80005dbe:	77c6                	ld	a5,112(sp)
    80005dc0:	7866                	ld	a6,120(sp)
    80005dc2:	688a                	ld	a7,128(sp)
    80005dc4:	692a                	ld	s2,136(sp)
    80005dc6:	69ca                	ld	s3,144(sp)
    80005dc8:	6a6a                	ld	s4,152(sp)
    80005dca:	7a8a                	ld	s5,160(sp)
    80005dcc:	7b2a                	ld	s6,168(sp)
    80005dce:	7bca                	ld	s7,176(sp)
    80005dd0:	7c6a                	ld	s8,184(sp)
    80005dd2:	6c8e                	ld	s9,192(sp)
    80005dd4:	6d2e                	ld	s10,200(sp)
    80005dd6:	6dce                	ld	s11,208(sp)
    80005dd8:	6e6e                	ld	t3,216(sp)
    80005dda:	7e8e                	ld	t4,224(sp)
    80005ddc:	7f2e                	ld	t5,232(sp)
    80005dde:	7fce                	ld	t6,240(sp)
    80005de0:	6111                	addi	sp,sp,256
    80005de2:	10200073          	sret
    80005de6:	00000013          	nop
    80005dea:	00000013          	nop
    80005dee:	0001                	nop

0000000080005df0 <timervec>:
    80005df0:	34051573          	csrrw	a0,mscratch,a0
    80005df4:	e10c                	sd	a1,0(a0)
    80005df6:	e510                	sd	a2,8(a0)
    80005df8:	e914                	sd	a3,16(a0)
    80005dfa:	710c                	ld	a1,32(a0)
    80005dfc:	7510                	ld	a2,40(a0)
    80005dfe:	6194                	ld	a3,0(a1)
    80005e00:	96b2                	add	a3,a3,a2
    80005e02:	e194                	sd	a3,0(a1)
    80005e04:	4589                	li	a1,2
    80005e06:	14459073          	csrw	sip,a1
    80005e0a:	6914                	ld	a3,16(a0)
    80005e0c:	6510                	ld	a2,8(a0)
    80005e0e:	610c                	ld	a1,0(a0)
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	30200073          	mret
	...

0000000080005e1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e1a:	1141                	addi	sp,sp,-16
    80005e1c:	e422                	sd	s0,8(sp)
    80005e1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e20:	0c0007b7          	lui	a5,0xc000
    80005e24:	4705                	li	a4,1
    80005e26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e28:	c3d8                	sw	a4,4(a5)
}
    80005e2a:	6422                	ld	s0,8(sp)
    80005e2c:	0141                	addi	sp,sp,16
    80005e2e:	8082                	ret

0000000080005e30 <plicinithart>:

void
plicinithart(void)
{
    80005e30:	1141                	addi	sp,sp,-16
    80005e32:	e406                	sd	ra,8(sp)
    80005e34:	e022                	sd	s0,0(sp)
    80005e36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	d14080e7          	jalr	-748(ra) # 80001b4c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e40:	0085171b          	slliw	a4,a0,0x8
    80005e44:	0c0027b7          	lui	a5,0xc002
    80005e48:	97ba                	add	a5,a5,a4
    80005e4a:	40200713          	li	a4,1026
    80005e4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e52:	00d5151b          	slliw	a0,a0,0xd
    80005e56:	0c2017b7          	lui	a5,0xc201
    80005e5a:	953e                	add	a0,a0,a5
    80005e5c:	00052023          	sw	zero,0(a0)
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret

0000000080005e68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e68:	1141                	addi	sp,sp,-16
    80005e6a:	e406                	sd	ra,8(sp)
    80005e6c:	e022                	sd	s0,0(sp)
    80005e6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	cdc080e7          	jalr	-804(ra) # 80001b4c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e78:	00d5179b          	slliw	a5,a0,0xd
    80005e7c:	0c201537          	lui	a0,0xc201
    80005e80:	953e                	add	a0,a0,a5
  return irq;
}
    80005e82:	4148                	lw	a0,4(a0)
    80005e84:	60a2                	ld	ra,8(sp)
    80005e86:	6402                	ld	s0,0(sp)
    80005e88:	0141                	addi	sp,sp,16
    80005e8a:	8082                	ret

0000000080005e8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e8c:	1101                	addi	sp,sp,-32
    80005e8e:	ec06                	sd	ra,24(sp)
    80005e90:	e822                	sd	s0,16(sp)
    80005e92:	e426                	sd	s1,8(sp)
    80005e94:	1000                	addi	s0,sp,32
    80005e96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	cb4080e7          	jalr	-844(ra) # 80001b4c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ea0:	00d5151b          	slliw	a0,a0,0xd
    80005ea4:	0c2017b7          	lui	a5,0xc201
    80005ea8:	97aa                	add	a5,a5,a0
    80005eaa:	c3c4                	sw	s1,4(a5)
}
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	64a2                	ld	s1,8(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret

0000000080005eb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005eb6:	1141                	addi	sp,sp,-16
    80005eb8:	e406                	sd	ra,8(sp)
    80005eba:	e022                	sd	s0,0(sp)
    80005ebc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ebe:	479d                	li	a5,7
    80005ec0:	04a7cc63          	blt	a5,a0,80005f18 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ec4:	0023d797          	auipc	a5,0x23d
    80005ec8:	13c78793          	addi	a5,a5,316 # 80243000 <disk>
    80005ecc:	00a78733          	add	a4,a5,a0
    80005ed0:	6789                	lui	a5,0x2
    80005ed2:	97ba                	add	a5,a5,a4
    80005ed4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ed8:	eba1                	bnez	a5,80005f28 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005eda:	00451713          	slli	a4,a0,0x4
    80005ede:	0023f797          	auipc	a5,0x23f
    80005ee2:	1227b783          	ld	a5,290(a5) # 80245000 <disk+0x2000>
    80005ee6:	97ba                	add	a5,a5,a4
    80005ee8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005eec:	0023d797          	auipc	a5,0x23d
    80005ef0:	11478793          	addi	a5,a5,276 # 80243000 <disk>
    80005ef4:	97aa                	add	a5,a5,a0
    80005ef6:	6509                	lui	a0,0x2
    80005ef8:	953e                	add	a0,a0,a5
    80005efa:	4785                	li	a5,1
    80005efc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f00:	0023f517          	auipc	a0,0x23f
    80005f04:	11850513          	addi	a0,a0,280 # 80245018 <disk+0x2018>
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	606080e7          	jalr	1542(ra) # 8000250e <wakeup>
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	8a050513          	addi	a0,a0,-1888 # 800087b8 <syscalls+0x330>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	628080e7          	jalr	1576(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f28:	00003517          	auipc	a0,0x3
    80005f2c:	8a850513          	addi	a0,a0,-1880 # 800087d0 <syscalls+0x348>
    80005f30:	ffffa097          	auipc	ra,0xffffa
    80005f34:	618080e7          	jalr	1560(ra) # 80000548 <panic>

0000000080005f38 <virtio_disk_init>:
{
    80005f38:	1101                	addi	sp,sp,-32
    80005f3a:	ec06                	sd	ra,24(sp)
    80005f3c:	e822                	sd	s0,16(sp)
    80005f3e:	e426                	sd	s1,8(sp)
    80005f40:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f42:	00003597          	auipc	a1,0x3
    80005f46:	8a658593          	addi	a1,a1,-1882 # 800087e8 <syscalls+0x360>
    80005f4a:	0023f517          	auipc	a0,0x23f
    80005f4e:	15e50513          	addi	a0,a0,350 # 802450a8 <disk+0x20a8>
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	d78080e7          	jalr	-648(ra) # 80000cca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f5a:	100017b7          	lui	a5,0x10001
    80005f5e:	4398                	lw	a4,0(a5)
    80005f60:	2701                	sext.w	a4,a4
    80005f62:	747277b7          	lui	a5,0x74727
    80005f66:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f6a:	0ef71163          	bne	a4,a5,8000604c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f6e:	100017b7          	lui	a5,0x10001
    80005f72:	43dc                	lw	a5,4(a5)
    80005f74:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f76:	4705                	li	a4,1
    80005f78:	0ce79a63          	bne	a5,a4,8000604c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f7c:	100017b7          	lui	a5,0x10001
    80005f80:	479c                	lw	a5,8(a5)
    80005f82:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f84:	4709                	li	a4,2
    80005f86:	0ce79363          	bne	a5,a4,8000604c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	47d8                	lw	a4,12(a5)
    80005f90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f92:	554d47b7          	lui	a5,0x554d4
    80005f96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f9a:	0af71963          	bne	a4,a5,8000604c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	4705                	li	a4,1
    80005fa4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa6:	470d                	li	a4,3
    80005fa8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005faa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fac:	c7ffe737          	lui	a4,0xc7ffe
    80005fb0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db875f>
    80005fb4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fb6:	2701                	sext.w	a4,a4
    80005fb8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fba:	472d                	li	a4,11
    80005fbc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fbe:	473d                	li	a4,15
    80005fc0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fc2:	6705                	lui	a4,0x1
    80005fc4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fc6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fca:	5bdc                	lw	a5,52(a5)
    80005fcc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fce:	c7d9                	beqz	a5,8000605c <virtio_disk_init+0x124>
  if(max < NUM)
    80005fd0:	471d                	li	a4,7
    80005fd2:	08f77d63          	bgeu	a4,a5,8000606c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fd6:	100014b7          	lui	s1,0x10001
    80005fda:	47a1                	li	a5,8
    80005fdc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fde:	6609                	lui	a2,0x2
    80005fe0:	4581                	li	a1,0
    80005fe2:	0023d517          	auipc	a0,0x23d
    80005fe6:	01e50513          	addi	a0,a0,30 # 80243000 <disk>
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	e6c080e7          	jalr	-404(ra) # 80000e56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ff2:	0023d717          	auipc	a4,0x23d
    80005ff6:	00e70713          	addi	a4,a4,14 # 80243000 <disk>
    80005ffa:	00c75793          	srli	a5,a4,0xc
    80005ffe:	2781                	sext.w	a5,a5
    80006000:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006002:	0023f797          	auipc	a5,0x23f
    80006006:	ffe78793          	addi	a5,a5,-2 # 80245000 <disk+0x2000>
    8000600a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000600c:	0023d717          	auipc	a4,0x23d
    80006010:	07470713          	addi	a4,a4,116 # 80243080 <disk+0x80>
    80006014:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006016:	0023e717          	auipc	a4,0x23e
    8000601a:	fea70713          	addi	a4,a4,-22 # 80244000 <disk+0x1000>
    8000601e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006020:	4705                	li	a4,1
    80006022:	00e78c23          	sb	a4,24(a5)
    80006026:	00e78ca3          	sb	a4,25(a5)
    8000602a:	00e78d23          	sb	a4,26(a5)
    8000602e:	00e78da3          	sb	a4,27(a5)
    80006032:	00e78e23          	sb	a4,28(a5)
    80006036:	00e78ea3          	sb	a4,29(a5)
    8000603a:	00e78f23          	sb	a4,30(a5)
    8000603e:	00e78fa3          	sb	a4,31(a5)
}
    80006042:	60e2                	ld	ra,24(sp)
    80006044:	6442                	ld	s0,16(sp)
    80006046:	64a2                	ld	s1,8(sp)
    80006048:	6105                	addi	sp,sp,32
    8000604a:	8082                	ret
    panic("could not find virtio disk");
    8000604c:	00002517          	auipc	a0,0x2
    80006050:	7ac50513          	addi	a0,a0,1964 # 800087f8 <syscalls+0x370>
    80006054:	ffffa097          	auipc	ra,0xffffa
    80006058:	4f4080e7          	jalr	1268(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000605c:	00002517          	auipc	a0,0x2
    80006060:	7bc50513          	addi	a0,a0,1980 # 80008818 <syscalls+0x390>
    80006064:	ffffa097          	auipc	ra,0xffffa
    80006068:	4e4080e7          	jalr	1252(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000606c:	00002517          	auipc	a0,0x2
    80006070:	7cc50513          	addi	a0,a0,1996 # 80008838 <syscalls+0x3b0>
    80006074:	ffffa097          	auipc	ra,0xffffa
    80006078:	4d4080e7          	jalr	1236(ra) # 80000548 <panic>

000000008000607c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000607c:	7119                	addi	sp,sp,-128
    8000607e:	fc86                	sd	ra,120(sp)
    80006080:	f8a2                	sd	s0,112(sp)
    80006082:	f4a6                	sd	s1,104(sp)
    80006084:	f0ca                	sd	s2,96(sp)
    80006086:	ecce                	sd	s3,88(sp)
    80006088:	e8d2                	sd	s4,80(sp)
    8000608a:	e4d6                	sd	s5,72(sp)
    8000608c:	e0da                	sd	s6,64(sp)
    8000608e:	fc5e                	sd	s7,56(sp)
    80006090:	f862                	sd	s8,48(sp)
    80006092:	f466                	sd	s9,40(sp)
    80006094:	f06a                	sd	s10,32(sp)
    80006096:	0100                	addi	s0,sp,128
    80006098:	892a                	mv	s2,a0
    8000609a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000609c:	00c52c83          	lw	s9,12(a0)
    800060a0:	001c9c9b          	slliw	s9,s9,0x1
    800060a4:	1c82                	slli	s9,s9,0x20
    800060a6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060aa:	0023f517          	auipc	a0,0x23f
    800060ae:	ffe50513          	addi	a0,a0,-2 # 802450a8 <disk+0x20a8>
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	ca8080e7          	jalr	-856(ra) # 80000d5a <acquire>
  for(int i = 0; i < 3; i++){
    800060ba:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060bc:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060be:	0023db97          	auipc	s7,0x23d
    800060c2:	f42b8b93          	addi	s7,s7,-190 # 80243000 <disk>
    800060c6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060c8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060ca:	8a4e                	mv	s4,s3
    800060cc:	a051                	j	80006150 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060ce:	00fb86b3          	add	a3,s7,a5
    800060d2:	96da                	add	a3,a3,s6
    800060d4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060d8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060da:	0207c563          	bltz	a5,80006104 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060de:	2485                	addiw	s1,s1,1
    800060e0:	0711                	addi	a4,a4,4
    800060e2:	23548d63          	beq	s1,s5,8000631c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800060e6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060e8:	0023f697          	auipc	a3,0x23f
    800060ec:	f3068693          	addi	a3,a3,-208 # 80245018 <disk+0x2018>
    800060f0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060f2:	0006c583          	lbu	a1,0(a3)
    800060f6:	fde1                	bnez	a1,800060ce <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060f8:	2785                	addiw	a5,a5,1
    800060fa:	0685                	addi	a3,a3,1
    800060fc:	ff879be3          	bne	a5,s8,800060f2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006100:	57fd                	li	a5,-1
    80006102:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006104:	02905a63          	blez	s1,80006138 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006108:	f9042503          	lw	a0,-112(s0)
    8000610c:	00000097          	auipc	ra,0x0
    80006110:	daa080e7          	jalr	-598(ra) # 80005eb6 <free_desc>
      for(int j = 0; j < i; j++)
    80006114:	4785                	li	a5,1
    80006116:	0297d163          	bge	a5,s1,80006138 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000611a:	f9442503          	lw	a0,-108(s0)
    8000611e:	00000097          	auipc	ra,0x0
    80006122:	d98080e7          	jalr	-616(ra) # 80005eb6 <free_desc>
      for(int j = 0; j < i; j++)
    80006126:	4789                	li	a5,2
    80006128:	0097d863          	bge	a5,s1,80006138 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000612c:	f9842503          	lw	a0,-104(s0)
    80006130:	00000097          	auipc	ra,0x0
    80006134:	d86080e7          	jalr	-634(ra) # 80005eb6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006138:	0023f597          	auipc	a1,0x23f
    8000613c:	f7058593          	addi	a1,a1,-144 # 802450a8 <disk+0x20a8>
    80006140:	0023f517          	auipc	a0,0x23f
    80006144:	ed850513          	addi	a0,a0,-296 # 80245018 <disk+0x2018>
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	240080e7          	jalr	576(ra) # 80002388 <sleep>
  for(int i = 0; i < 3; i++){
    80006150:	f9040713          	addi	a4,s0,-112
    80006154:	84ce                	mv	s1,s3
    80006156:	bf41                	j	800060e6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006158:	4785                	li	a5,1
    8000615a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000615e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006162:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006166:	f9042983          	lw	s3,-112(s0)
    8000616a:	00499493          	slli	s1,s3,0x4
    8000616e:	0023fa17          	auipc	s4,0x23f
    80006172:	e92a0a13          	addi	s4,s4,-366 # 80245000 <disk+0x2000>
    80006176:	000a3a83          	ld	s5,0(s4)
    8000617a:	9aa6                	add	s5,s5,s1
    8000617c:	f8040513          	addi	a0,s0,-128
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	0aa080e7          	jalr	170(ra) # 8000122a <kvmpa>
    80006188:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000618c:	000a3783          	ld	a5,0(s4)
    80006190:	97a6                	add	a5,a5,s1
    80006192:	4741                	li	a4,16
    80006194:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006196:	000a3783          	ld	a5,0(s4)
    8000619a:	97a6                	add	a5,a5,s1
    8000619c:	4705                	li	a4,1
    8000619e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061a2:	f9442703          	lw	a4,-108(s0)
    800061a6:	000a3783          	ld	a5,0(s4)
    800061aa:	97a6                	add	a5,a5,s1
    800061ac:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b0:	0712                	slli	a4,a4,0x4
    800061b2:	000a3783          	ld	a5,0(s4)
    800061b6:	97ba                	add	a5,a5,a4
    800061b8:	05890693          	addi	a3,s2,88
    800061bc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800061be:	000a3783          	ld	a5,0(s4)
    800061c2:	97ba                	add	a5,a5,a4
    800061c4:	40000693          	li	a3,1024
    800061c8:	c794                	sw	a3,8(a5)
  if(write)
    800061ca:	100d0a63          	beqz	s10,800062de <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061ce:	0023f797          	auipc	a5,0x23f
    800061d2:	e327b783          	ld	a5,-462(a5) # 80245000 <disk+0x2000>
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061dc:	0023d517          	auipc	a0,0x23d
    800061e0:	e2450513          	addi	a0,a0,-476 # 80243000 <disk>
    800061e4:	0023f797          	auipc	a5,0x23f
    800061e8:	e1c78793          	addi	a5,a5,-484 # 80245000 <disk+0x2000>
    800061ec:	6394                	ld	a3,0(a5)
    800061ee:	96ba                	add	a3,a3,a4
    800061f0:	00c6d603          	lhu	a2,12(a3)
    800061f4:	00166613          	ori	a2,a2,1
    800061f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061fc:	f9842683          	lw	a3,-104(s0)
    80006200:	6390                	ld	a2,0(a5)
    80006202:	9732                	add	a4,a4,a2
    80006204:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006208:	20098613          	addi	a2,s3,512
    8000620c:	0612                	slli	a2,a2,0x4
    8000620e:	962a                	add	a2,a2,a0
    80006210:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006214:	00469713          	slli	a4,a3,0x4
    80006218:	6394                	ld	a3,0(a5)
    8000621a:	96ba                	add	a3,a3,a4
    8000621c:	6589                	lui	a1,0x2
    8000621e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006222:	94ae                	add	s1,s1,a1
    80006224:	94aa                	add	s1,s1,a0
    80006226:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006228:	6394                	ld	a3,0(a5)
    8000622a:	96ba                	add	a3,a3,a4
    8000622c:	4585                	li	a1,1
    8000622e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006230:	6394                	ld	a3,0(a5)
    80006232:	96ba                	add	a3,a3,a4
    80006234:	4509                	li	a0,2
    80006236:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000623a:	6394                	ld	a3,0(a5)
    8000623c:	9736                	add	a4,a4,a3
    8000623e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006242:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006246:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000624a:	6794                	ld	a3,8(a5)
    8000624c:	0026d703          	lhu	a4,2(a3)
    80006250:	8b1d                	andi	a4,a4,7
    80006252:	2709                	addiw	a4,a4,2
    80006254:	0706                	slli	a4,a4,0x1
    80006256:	9736                	add	a4,a4,a3
    80006258:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000625c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006260:	6798                	ld	a4,8(a5)
    80006262:	00275783          	lhu	a5,2(a4)
    80006266:	2785                	addiw	a5,a5,1
    80006268:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006274:	00492703          	lw	a4,4(s2)
    80006278:	4785                	li	a5,1
    8000627a:	02f71163          	bne	a4,a5,8000629c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000627e:	0023f997          	auipc	s3,0x23f
    80006282:	e2a98993          	addi	s3,s3,-470 # 802450a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006286:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006288:	85ce                	mv	a1,s3
    8000628a:	854a                	mv	a0,s2
    8000628c:	ffffc097          	auipc	ra,0xffffc
    80006290:	0fc080e7          	jalr	252(ra) # 80002388 <sleep>
  while(b->disk == 1) {
    80006294:	00492783          	lw	a5,4(s2)
    80006298:	fe9788e3          	beq	a5,s1,80006288 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000629c:	f9042483          	lw	s1,-112(s0)
    800062a0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800062a4:	00479713          	slli	a4,a5,0x4
    800062a8:	0023d797          	auipc	a5,0x23d
    800062ac:	d5878793          	addi	a5,a5,-680 # 80243000 <disk>
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b6:	0023f917          	auipc	s2,0x23f
    800062ba:	d4a90913          	addi	s2,s2,-694 # 80245000 <disk+0x2000>
    free_desc(i);
    800062be:	8526                	mv	a0,s1
    800062c0:	00000097          	auipc	ra,0x0
    800062c4:	bf6080e7          	jalr	-1034(ra) # 80005eb6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062c8:	0492                	slli	s1,s1,0x4
    800062ca:	00093783          	ld	a5,0(s2)
    800062ce:	94be                	add	s1,s1,a5
    800062d0:	00c4d783          	lhu	a5,12(s1)
    800062d4:	8b85                	andi	a5,a5,1
    800062d6:	cf89                	beqz	a5,800062f0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800062d8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062dc:	b7cd                	j	800062be <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062de:	0023f797          	auipc	a5,0x23f
    800062e2:	d227b783          	ld	a5,-734(a5) # 80245000 <disk+0x2000>
    800062e6:	97ba                	add	a5,a5,a4
    800062e8:	4689                	li	a3,2
    800062ea:	00d79623          	sh	a3,12(a5)
    800062ee:	b5fd                	j	800061dc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062f0:	0023f517          	auipc	a0,0x23f
    800062f4:	db850513          	addi	a0,a0,-584 # 802450a8 <disk+0x20a8>
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	b16080e7          	jalr	-1258(ra) # 80000e0e <release>
}
    80006300:	70e6                	ld	ra,120(sp)
    80006302:	7446                	ld	s0,112(sp)
    80006304:	74a6                	ld	s1,104(sp)
    80006306:	7906                	ld	s2,96(sp)
    80006308:	69e6                	ld	s3,88(sp)
    8000630a:	6a46                	ld	s4,80(sp)
    8000630c:	6aa6                	ld	s5,72(sp)
    8000630e:	6b06                	ld	s6,64(sp)
    80006310:	7be2                	ld	s7,56(sp)
    80006312:	7c42                	ld	s8,48(sp)
    80006314:	7ca2                	ld	s9,40(sp)
    80006316:	7d02                	ld	s10,32(sp)
    80006318:	6109                	addi	sp,sp,128
    8000631a:	8082                	ret
  if(write)
    8000631c:	e20d1ee3          	bnez	s10,80006158 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006320:	f8042023          	sw	zero,-128(s0)
    80006324:	bd2d                	j	8000615e <virtio_disk_rw+0xe2>

0000000080006326 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006326:	1101                	addi	sp,sp,-32
    80006328:	ec06                	sd	ra,24(sp)
    8000632a:	e822                	sd	s0,16(sp)
    8000632c:	e426                	sd	s1,8(sp)
    8000632e:	e04a                	sd	s2,0(sp)
    80006330:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006332:	0023f517          	auipc	a0,0x23f
    80006336:	d7650513          	addi	a0,a0,-650 # 802450a8 <disk+0x20a8>
    8000633a:	ffffb097          	auipc	ra,0xffffb
    8000633e:	a20080e7          	jalr	-1504(ra) # 80000d5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006342:	0023f717          	auipc	a4,0x23f
    80006346:	cbe70713          	addi	a4,a4,-834 # 80245000 <disk+0x2000>
    8000634a:	02075783          	lhu	a5,32(a4)
    8000634e:	6b18                	ld	a4,16(a4)
    80006350:	00275683          	lhu	a3,2(a4)
    80006354:	8ebd                	xor	a3,a3,a5
    80006356:	8a9d                	andi	a3,a3,7
    80006358:	cab9                	beqz	a3,800063ae <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000635a:	0023d917          	auipc	s2,0x23d
    8000635e:	ca690913          	addi	s2,s2,-858 # 80243000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006362:	0023f497          	auipc	s1,0x23f
    80006366:	c9e48493          	addi	s1,s1,-866 # 80245000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000636a:	078e                	slli	a5,a5,0x3
    8000636c:	97ba                	add	a5,a5,a4
    8000636e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006370:	20078713          	addi	a4,a5,512
    80006374:	0712                	slli	a4,a4,0x4
    80006376:	974a                	add	a4,a4,s2
    80006378:	03074703          	lbu	a4,48(a4)
    8000637c:	ef21                	bnez	a4,800063d4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000637e:	20078793          	addi	a5,a5,512
    80006382:	0792                	slli	a5,a5,0x4
    80006384:	97ca                	add	a5,a5,s2
    80006386:	7798                	ld	a4,40(a5)
    80006388:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000638c:	7788                	ld	a0,40(a5)
    8000638e:	ffffc097          	auipc	ra,0xffffc
    80006392:	180080e7          	jalr	384(ra) # 8000250e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006396:	0204d783          	lhu	a5,32(s1)
    8000639a:	2785                	addiw	a5,a5,1
    8000639c:	8b9d                	andi	a5,a5,7
    8000639e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063a2:	6898                	ld	a4,16(s1)
    800063a4:	00275683          	lhu	a3,2(a4)
    800063a8:	8a9d                	andi	a3,a3,7
    800063aa:	fcf690e3          	bne	a3,a5,8000636a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063ae:	10001737          	lui	a4,0x10001
    800063b2:	533c                	lw	a5,96(a4)
    800063b4:	8b8d                	andi	a5,a5,3
    800063b6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063b8:	0023f517          	auipc	a0,0x23f
    800063bc:	cf050513          	addi	a0,a0,-784 # 802450a8 <disk+0x20a8>
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	a4e080e7          	jalr	-1458(ra) # 80000e0e <release>
}
    800063c8:	60e2                	ld	ra,24(sp)
    800063ca:	6442                	ld	s0,16(sp)
    800063cc:	64a2                	ld	s1,8(sp)
    800063ce:	6902                	ld	s2,0(sp)
    800063d0:	6105                	addi	sp,sp,32
    800063d2:	8082                	ret
      panic("virtio_disk_intr status");
    800063d4:	00002517          	auipc	a0,0x2
    800063d8:	48450513          	addi	a0,a0,1156 # 80008858 <syscalls+0x3d0>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	16c080e7          	jalr	364(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
