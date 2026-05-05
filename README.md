# Docs&Links
module doc https://zmk.dev/docs/development/hardware-integration/new-shield?keyboard-type=split&interconnect=pro_micro
Useful ZMK video https://www.youtube.com/watch?v=IIsZeWX2LEQ
ref https://github.com/linkarzu/zmk-keyboard-toucan/blob/main/boards/shields/toucan/toucan.keymap
homerow mod https://github.com/linkarzu/linkarzu-glove80/blob/main/config/glove80.keymap

# TODO
- Update wiring pinout
- add layers
- Use - You switch between paired devices using &bt BT_SEL 0, &bt BT_SEL 1
- add Microcontroller wiring
- add Kanata companion configs - Windows & Linux
- add homerow mod

# dtsi transform draft

// | SW01 | SW02 | SW03 | SW04 | SW05 | SW06 |  
// | SW07 | SW08 | SW09 | SW10 | SW11 | SW12 |
// | SW13 | SW14 | SW15 | SW16 | SW17 | SW18 |  
// | SW19 | SW20 | SW21 | SW22 | SW23 | SW24 | 
//        | SW25 | SW26 | SW27 | 
//                                           | SW28 | SW29 |
//                                                  | SW30 |
//                             | SW31 | SW32 | SW33 | SW34 |

# old map
        map = <
RC(0,0) RC(0,1) RC(0,2) RC(0,3) RC(0,4) RC(0,5)                                                     RC(0,10) RC(0,11) RC(0,12) RC(0,13) RC(0,14) RC(0,15)
RC(1,0) RC(1,1) RC(1,2) RC(1,3) RC(1,4) RC(1,5)                                                     RC(1,10) RC(1,11) RC(1,12) RC(1,13) RC(1,14) RC(1,15)
RC(2,0) RC(2,1) RC(2,2) RC(2,3) RC(2,4) RC(2,5)                                                     RC(2,10) RC(2,11) RC(2,12) RC(2,13) RC(2,14) RC(2,15)
RC(3,0) RC(3,1) RC(3,2) RC(3,3) RC(3,4) RC(3,5)         RC(3,6) RC(3,7)     RC(3,8) RC(3,9)         RC(3,10) RC(3,11) RC(3,12) RC(3,13) RC(3,14) RC(3,15)
        RC(4,1) RC(4,2) RC(4,3) RC(4,4)         RC(4,5) RC(4,6) RC(4,7)     RC(4,8) RC(4,9) RC(4,10)         RC(4,11) RC(4,12) RC(4,13) RC(4,14)
                                                                RC(5,7)     RC(5,8)
        >;

# Microcontroller wiring
| Matrix | Pin label | ZMK reference |
| - | - | - |
| R0 | 009 | &gpio0 9 |
| R1 | 010 | &gpio0 10 |
| R2 | 111 | &pro_micro 14 |
| R3 | 113 | &pro_micro 15 |
| R4 | 115 | &pro_micro 18 |
| R5 | 002 | &pro_micro 19 |
| C0 | 106 | &pro_micro 10 |
| C1 | 104 | &pro_micro 9 |
| C2 | 011 | &pro_micro 8 |
| C3 | 100 | &pro_micro 7 |
| C4 | 024 | &pro_micro 6 |
| C5 | 022 | &pro_micro 5 |
| C6 | 020 | &pro_micro 4 |
| C7 | 017 | &pro_micro 3 |
