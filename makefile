# requires GNU make
SHELL=/bin/bash

.DELETE_ON_ERROR:

# 1) Build .aux (and other .fmt files) by running pdflatex once
%.aux: %.tex
	pdflatex --shell-escape -halt-on-error $<

# 2) Build .bbl from the .aux that just got made
%.bbl: %.aux
	bibtex $*

# 3) Build the final PDF—depend on both the .tex and on the .bbl
#    so that Make knows to rebuild it after you’ve run bibtex
%.pdf: %.tex %.bbl
	pdflatex --shell-escape $<
	# rerun until no “Rerun to get …” messages
	while grep -q 'Rerun to get ' $*.log; do \
	  pdflatex --shell-escape $<; \
	done

#%.pdf %.aux %.idx: %.tex %.bbl
#	pdflatex --shell-escape $<
#	while grep 'Rerun to get ' $*.log ; do pdflatex $< ; done
#	#pdflatex -halt-on-error -file-line-error $<
#	#while grep 'Rerun to get ' $*.log ; do pdflatex -halt-on-error $< ; done
%.ind: %.idx
	makeindex $*
#%.bbl: %.aux
#	bibtex $*
%.pdftex %.pdftex_t: %.fig
	fig2dev -L pdftex_t -p $*.pdftex $< $*.pdftex_t
	fig2dev -L pdftex $< $*.pdftex

all: report.pdf report-submission.pdf

report-submission.tex: report.tex
	sed -e 's/^%\(\\submissiontrue\)/\1/' $< >$@

report.pdf: logo-dcst-colour.pdf

# extract number of first and last page of the main chapters from the AUX file
WORDCOUNT_FILE=report
INTRODUCTION_AUX=chapters/01_introduction
FIRSTPAGE?=$(shell sed -ne 's/^\\newlabel{firstcontentpage}{{[0-9\.]*}{\([0-9]*\)}.*/\1/p' $(INTRODUCTION_AUX).aux)
LASTPAGE ?=$(shell sed -ne 's/^\\newlabel{lastcontentpage}{{[0-9\.]*}{\([0-9]*\)}.*/\1/p' $(WORDCOUNT_FILE).aux)
LASTPAGE := $(shell expr $(LASTPAGE) - 1)

# requires ghostscript
# wordcount: $(WORDCOUNT_FILE).pdf
	# gs -q -dSAFER -sDEVICE=txtwrite -o - \
	   # -dFirstPage=$(FIRSTPAGE) -dLastPage=$(LASTPAGE) $< | \
	# egrep '[A-Za-z]{3}' | wc -w

wordcount: $(WORDCOUNT_FILE).pdf
	gs -q -dSAFER -sDEVICE=txtwrite -o - \
	   -dFirstPage=10 -dLastPage=59 $< | \
	egrep '[A-Za-z]{3}' | wc -w

clean:
	rm -f *.log *.aux *.toc *.bbl *.ind *.lot *.lof *.out *~
	rm -f chapters/*.aux
	rm -f report-submission.tex
