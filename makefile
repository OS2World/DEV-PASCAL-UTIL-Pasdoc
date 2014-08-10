#makefile
#
#For Free Pascal

PPC = ppc386
PRJDIR = D:\PasDocPP
SRCDIR = D:\PasDocPP\source
FLAGS = -B -S2 -Sd -TOS2 -FU$(PRJDIR)\Output -Fu$(SRCDIR)\component -Fu$(SRCDIR)\OptionParser -Fu$(SRCDIR)\Console -Fi$(SRCDIR)\component -Fi$(SRCDIR)\OptionParser -Fi$(SRCDIR)\Console

#i aqui els targets	
all : pasdoc.exe

pasdoc.exe :
	$(PPC) $(FLAGS) $(SRCDIR)\Console\PasDoc_Console.dpr 
	-copy $(SRCDIR)\console\PasDoc_Console.exe $(PRJDIR)\PasDoc.exe
	
clean : 
	-del /N $(PRJDIR)\output\*.*
	-del /N $(SRCDIR)\console\*.*~
	-del /N $(SRCDIR)\component\*.*~
	-del /N $(SRCDIR)\optionparser\*.*~
	-del $(SRCDIR)\console\PasDoc_Console.exe
	-del $(PRJDIR)\PasDoc.exe