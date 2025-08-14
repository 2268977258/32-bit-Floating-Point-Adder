sim:
		vcs -full64 \
    -f filelist.f \
    -top fp32_adder_tb \
    -R -v2005 -timescale=1ns/1ns -debug_acc+dmptf \
    -debug_region+cell+encrypt+lib +lint=TFIPC-L \
    -debug_access+all +vcd+vcdpluson +memcbk +error+999 -LDFLAGS -Wl,--no-as-needed -kdb -lca -l sim.log \
		+define+SIM +define+$(MODE)

clean:
		rm -rf ./csrc ./DVEfiles *.daidir ./csrc  						\
		*.log  *.vpd  *.vdb  simv* *.key				\
		+race.out* novas* verdi* *fsdb apb2apb_async *.dot *.vcd \
		*.alias *.chain *.field *.lock *.netwk *.p2s *.pidat *.podat *.sinf *.slist *.str *.tlist *.xlist *.pdf *.dat

verdi:
		verdi -f filelist.f -top fp32_adder_tb -nologo -ssf *.fsdb -sswr ./signal.rc