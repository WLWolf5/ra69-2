#!/bin/bash
WRT_VER="lede"
TEXT_SUC_LE="LEDE编译成功"
TEXT_FAIL_LE="LEDE编译失败"
TEXT_SUC_RB="Robimarko编译成功"
TEXT_FAIL_RB="Robimarko编译失败"

make download -j32

if [ "$WRT_VER" == "lede" ]; then
    make -j2 || make package/mbedtls/compile -j2 && make -j2 && curl --data chat_id="5433096526" --data "text=$TEXT_SUC_LE" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage" || make -j$(nproc) V=s || curl --data chat_id="5433096526" --data "text=$TEXT_FAIL_LE" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage"
elif [ "$WRT_VER" == "robi" ]; then
    make -j2 && curl --data chat_id="5433096526" --data "text=$TEXT_SUC_RB" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage" || make -j$(nproc) V=s || curl --data chat_id="5433096526" --data "text=$TEXT_FAIL_RB" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage"
fi
