cd ./ext/asm6; make all
cd ../../game
../ext/asm6/asm6 gradroad.asm
cd ..
mednafen game/gradroad.bin