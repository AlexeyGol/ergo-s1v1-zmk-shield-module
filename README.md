# Docs&Links
module doc https://zmk.dev/docs/development/hardware-integration/new-shield?keyboard-type=split&interconnect=pro_micro

# TODO
- Update wiring pinout
- add layers
- Use - You switch between paired devices using &bt BT_SEL 0, &bt BT_SEL 1
- add Microcontroller wiring

# dtsi transform draft

// | SW01 | SW02 | SW03 | SW04 | SW05 | SW06 |  
// | SW07 | SW08 | SW09 | SW10 | SW11 | SW12 |
// | SW13 | SW14 | SW15 | SW16 | SW17 | SW18 |  
// | SW19 | SW20 | SW21 | SW22 | SW23 | SW24 | 
//        | SW25 | SW26 | SW27 | 
//                                           | SW28 | SW29 |
//                                                  | SW30 |
//                             | SW31 | SW32 | SW33 | SW34 |

# Microcontroller wiring
| Matrix | Pin label | ZMK pin |
| - | - | - |
| R0 | 106 | 10 |
| R1 | 106 | 10 |
| R2 | 106 | 10 |
| R3 | 106 | 10 |
| R4 | 106 | 10 |
| C0 | 106 | 10 |
| C1 | 106 | 10 |
| C2 | 106 | 10 |
| C3 | 106 | 10 |
| C4 | 106 | 10 |
| C5 | 106 | 10 |
| C6 | 106 | 10 |
| C7 | 106 | 10 |
