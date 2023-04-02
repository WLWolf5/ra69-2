#!/bin/bash
TEXT_SUC="LEDE编译成功"
TEXT_FAIL="LEDE编译成功"
make download -j32
make package/mbedtls/compile -j2
make -j2 && curl --data chat_id="5433096526" --data "text=$TEXT_SUC" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage" || make -j$(nproc) V=s || curl --data chat_id="5433096526" --data "text=$TEXT_FAIL" "https://api.telegram.org/bot6059390181:AAHCsjxsPfsXAyAvXcRxcOjIVaifDICW5fA/sendMessage"
