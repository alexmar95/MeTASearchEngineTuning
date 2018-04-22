#!/bin/bash

calcRes (){
    maxres="0.0"
    TARGET_KEY="$1"
    METHOD="$2"
    CF="config.toml"
    RES="$METHOD""-RESULTS.txt"
    rm "results/""$RES" &>/dev/null
    data="$TARGET_KEY = 0 "
    result="0.0"
    #echo "seq = $(seq "$3" "$4" "$5")"
    #exit
    sed -i "s/\(superranker *= *\).*/\1"\"$METHOD\""/" $CF
    for REPLACEMENT_VALUE in $(seq "$3" "$4" "$5")
    do
	sed -i "s/\($TARGET_KEY *= *\).*/\1$REPLACEMENT_VALUE/" $CF
	result=$(./competition "$CF" | grep -E 'The MAP for the training queries is'| grep -Eo "[0-9]+([.][0-9]+)?")
	if [ `expr "$result" ">" "$maxres"` == "1" ]; then
	  #echo "in $result $maxres"
	  maxres=$result
	  data="$TARGET_KEY = $REPLACEMENT_VALUE"
	  #echo "out $result $maxres"
	fi
	echo "$TARGET_KEY = $REPLACEMENT_VALUE $result" >>"results/""$METHOD""-RESULTS.txt"
    done
    echo "$METHOD:" >> "results/final_results.txt"
    valoare=`cat "results/""$METHOD""-RESULTS.txt" | grep "$data"`
    echo "$valoare" >> "results/final_results.txt"
    echo "" >> "results/final_results.txt"
}

all (){
    echo "running all:"
    bm25
    dirichlet
    jelinek
    pivoted
    absolute
}

bm25 (){
    echo "running bm25"
    maxres="0.0"
    METHOD="bm25"
    CF="config.toml"
    RES="$METHOD""-RESULTS.txt"
    rm "results/""$RES" &>/dev/null
    data="$B = 0, $K1 = 0, $K = $0"
    result="0.0"
    K1="bm25k1"
    K3="bm25k3"
    B="bm25b"
    sed -i "s/\(superranker *= *\).*/\1"\"$METHOD\""/" $CF
    for b in $(seq 0.8 0.05 1)
    do
	sed -i "s/\($B *= *\).*/\1$b/" $CF
	for k1 in $(seq 1.7 0.05 2)
	do
	    sed -i "s/\($K1 *= *\).*/\1$k1/" $CF
	    k3=0
	    sed -i "s/\($K3 *= *\).*/\1$k3/" $CF
	    result=$(./competition "$CF" | grep -E 'The MAP for the training queries is'| grep -Eo "[0-9]+([.][0-9]+)?")
	    if [ `expr "$result" ">" "$maxres"` == "1" ]; then
		maxres=$result
		data="$B = $b, $K1 = $k1, $K3 = $k3"
		echo "$data"
	    fi
	    echo "$B = $b, $K1 = $k1, $K3 = $k3 $result" >> "results/""$METHOD""-RESULTS.txt"
	done
    done
    echo "$data"
    echo "$METHOD:" >> "results/final_results.txt"
    valoare=`cat "results/""$METHOD""-RESULTS.txt" | grep "$data"`
    echo "$valoare" >> "results/final_results.txt"
    echo "" >> "results/final_results.txt"

}

dirichlet (){
    echo ""
    echo "running dirichlet"
    TARGET_KEY="mu"
    METHOD="dirichlet-prior"
    #mu>=0
    calcRes $TARGET_KEY $METHOD 600 10 1000
}

absolute (){
    echo ""
    echo "running absolute-discount"
    TARGET_KEY="delta"
    METHOD="absolute-discount"
    #0<=delta<=1
    calcRes $TARGET_KEY $METHOD 0 0.05 1
}

jelinek (){
    echo ""
    echo "running jelinek-mercer"
    TARGET_KEY="lambda"
    METHOD="jelinek-mercer"
    #0<=lambda<=1
    calcRes $TARGET_KEY $METHOD 0 0.05 1
}

pivoted (){
    echo ""
    echo "running pivoted-length"
    TARGET_KEY="nashpa"
    METHOD="pivoted-length"
    #0<=s(nashpa)<=1
    calcRes $TARGET_KEY $METHOD 0 0.05 1
}

mkdir results &>/dev/null
export LANG=en_US
case "$1" in
"all") rm results/final_results.txt &>/dev/null
touch results/final_results.txt &>/dev/null 
all
;;
"bm25") bm25
;;
"dirichlet") dirichlet
;;
"jelinek") jelinek
;;
"pivoted") pivoted
;;
"absolute") absolute
;;
*) echo "bad arguments"
;;
esac
