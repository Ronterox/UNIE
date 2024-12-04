#!/usr/bin/env bash

set -e

# CSP: default-src * 'unsafe-inline' 'unsafe-eval'; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src * 'unsafe-inline'; img-src * data: blob: 'unsafe-inline'; frame-src *; style-src * 'unsafe-inline';

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <pdf> <start-page> <end-page>"
    exit 1
fi

firefoxConfig="browserName=firefox moz:firefoxOptions.args=[--profile=$HOME/.mozilla/firefox/vu8s1cle.default-release-1662927092603]"

sideFile="gpt.side"
pdf=$1
startPage=$2
endPage=$3

name="${pdf##*/}"
outDir="${name%.*}"
outDir="${outDir//[[:space:]]/_}"
outDir="${outDir,,}"

outFile="$outDir"
timeout=120

genSideFile() {
local content=${1//\"/\\\"}
local query=$2
local timeout=$(($3 * 1000))
cat > "$outDir/$sideFile" << EOM
{
  "id": "513e4bb6-ec62-4b20-9328-ed06ee5cc7e3",
  "version": "2.0",
  "name": "Chat Gpt",
  "url": "https://chatgpt.com",
  "tests": [{
    "id": "ec3dda12-9dca-494e-9110-894eb061e01a",
    "name": "hi",
    "commands": [{
      "id": "c57b539f-be55-463f-9c5e-c34187e2c841",
      "comment": "",
      "command": "open",
      "target": "/",
      "targets": [],
      "value": ""
    }, {
      "id": "53cb5a38-f183-48a2-a877-3cad9218c315",
      "comment": "",
      "command": "setWindowSize",
      "target": "948x1016",
      "targets": [],
      "value": ""
    }, {
      "id": "233d8fb9-4af3-4311-990b-9c5d3286f1e1",
      "comment": "",
      "command": "click",
      "target": "css=.placeholder",
      "targets": [
        ["css=.placeholder", "css:finder"],
        ["xpath=//div[@id='prompt-textarea']/p", "xpath:idRelative"],
        ["xpath=//p", "xpath:position"]
      ],
      "value": ""
    }, {
      "id": "858c08fa-d839-460b-8f3c-be3cf383c61b",
      "comment": "",
      "command": "editContent",
      "target": "//*[@id=\"prompt-textarea\"]",
      "targets": [
        ["css=.\\\_prosemirror-parent_15ceg_1", "css:finder"],
        ["xpath=//div/div[2]/div/div/div[2]/div", "xpath:position"]
      ],
      "value": "${content}\n\n${query}"
    }, {
      "id": "8f3c7c85-074f-4f4e-aced-c834a6bac227",
      "comment": "",
      "command": "click",
      "target": "css=.icon-2xl",
      "targets": [
        ["css=.icon-2xl", "css:finder"]
      ],
      "value": ""
    }, {
      "id": "7d4cf37d-40c2-442e-bc7d-13a8b6d58cc3",
      "comment": "",
      "command": "waitForElementVisible",
      "target": "css=.items-center > span:nth-child(2) .icon-md-heavy",
      "targets": [
        ["css=.items-center > span:nth-child(2) .icon-md-heavy", "css:finder"]
      ],
      "value": "${timeout}"
    }, {
      "id": "4328952c-81f0-49a3-a476-76d7e72027d9",
      "comment": "",
      "command": "storeText",
      "target": "//*[@data-message-author-role=\"assistant\"]",
      "targets": [],
      "value": "answer"
    }, {
      "id": "ab52c96f-6ed0-4e29-ae4a-5608f3395b8e",
      "comment": "",
      "command": "echo",
      "target": "\${answer}",
      "targets": [],
      "value": ""
    }]
  }],
  "suites": [{
    "id": "9797eb4e-46fb-4c4b-8e76-25d3d0c51b17",
    "name": "Default Suite",
    "persistSession": false,
    "parallel": false,
    "timeout": 300,
    "tests": ["ec3dda12-9dca-494e-9110-894eb061e01a"]
  }],
  "urls": ["https://chatgpt.com/"],
  "plugins": []
}
EOM
}

mkdir -p "$outDir" "$outDir/pdf" "$outDir/json"
query="De la informacion anterior genera preguntas de seleccion simple en forma de json siguiendo:\n{ question: string, answers: string[], correct: number }"

i=$startPage
while [ $i -lt $endPage ]; do
    start=$(date +%s)

    qpdf "$pdf" --pages . "$i" -- "$outDir/pdf/${outFile}_$i.pdf"
    pdftotext -raw -enc 'UTF-8' "$outDir/pdf/${outFile}_$i.pdf" "$outDir/pdf/${outFile}_$i.txt"

    parse_file=$(tr -cd '[:print:]' < "$outDir/pdf/${outFile}_$i.txt")
    genSideFile "$parse_file" "$query" "$timeout"

    if selenium-side-runner -c "$firefoxConfig" "$outDir/$sideFile" | grep -Pzo '\[\s*\{(?:.|\n)*?\}\s*\]' > "$outDir/json/${outFile}_$i.json"; then
        timeout=$(echo "$(date +%s) - $start + 5" | bc -l)
    fi

    i=$((i+1))

    secs=$(echo "$(date +%s) - $start" | bc -l)
    mins=$(((secs / 60) + (secs % 60 > 0)))
    echo "Page $i/$endPage took ${mins}m $(echo "$secs % 60" | bc -l)s"

    total=$(echo "$secs * ($endPage - $i)" | bc -l)
    mins=$(((total / 60) + (total % 60 > 0)))
    echo "Expected to take ${mins}m $(echo "$total % 60" | bc -l)s"
done

echo "Done! Now parsing..."

./parse.sh "$outDir"

echo "Now Really done!"

