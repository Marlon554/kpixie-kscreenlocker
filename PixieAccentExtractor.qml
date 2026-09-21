/*
    Wallpaper-based accent color extraction for kscreenlocker.
    Extraction algorithm ported unchanged from Pixie SDDM's Main.qml.

    kscreenlocker exposes `wallpaper` as an Item, but Canvas.drawImage() can't
    take an Item directly, so we grabToImage() it first and feed that to the
    Canvas.

    SPDX-License-Identifier: MIT
*/

import QtQuick

Item {
    id: root

    property Item source: null
    property color fallbackColor: "#8AB4F8"
    property color extractedColor: fallbackColor
    property bool processed: false

    x: -1000
    y: -1000
    width: 1
    height: 1

    // Holds the grabbed snapshot that the Canvas below samples.
    Image {
        id: sampledImage
        width: 60
        height: 60
        asynchronous: true
        cache: false
        visible: false
        fillMode: Image.Stretch

        onStatusChanged: {
            if (status === Image.Ready) {
                extractor.requestPaint();
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: true
        running: root.source !== null && !root.processed
        onTriggered: root.captureSource()
    }

    Canvas {
        id: extractor
        width: 60
        height: 60
        renderTarget: Canvas.Image
        property int retries: 0

        onPaint: {
            if (!sampledImage.source || sampledImage.status !== Image.Ready) {
                return;
            }

            const ctx = getContext("2d");
            const res = 60;
            ctx.clearRect(0, 0, res, res);
            ctx.drawImage(sampledImage, 0, 0, res, res);
            const imgData = ctx.getImageData(0, 0, res, res).data;

            if (!imgData || imgData.length === 0) {
                return;
            }

            const histogram = new Array(36).fill(0);
            const sampleColors = new Array(36).fill(null);
            let vibrantFound = false;

            let pixelSum = 0;
            for (let p = 0; p < imgData.length; p++) {
                pixelSum += imgData[p];
            }

            if (pixelSum === 0) {
                extractor.retries++;
                if (extractor.retries > 3) {
                    root.extractedColor = "#D0D0D0";
                    root.processed = true;
                }
                return;
            }
            extractor.retries = 0;

            for (let i = 0; i < imgData.length; i += 4) {
                const r = imgData[i] / 255;
                const g = imgData[i + 1] / 255;
                const b = imgData[i + 2] / 255;
                const pCol = Qt.rgba(r, g, b, 1.0);

                if (pCol.hsvSaturation > 0.3 && pCol.hsvValue > 0.15) {
                    const h = pCol.hsvHue * 360;
                    if (h < 0) {
                        continue;
                    }

                    const bIdx = Math.floor(h / 10) % 36;
                    const weight = pCol.hsvSaturation * pCol.hsvValue;
                    histogram[bIdx] += weight;

                    if (!sampleColors[bIdx] || weight > (sampleColors[bIdx].hsvSaturation * sampleColors[bIdx].hsvValue)) {
                        sampleColors[bIdx] = pCol;
                    }
                    vibrantFound = true;
                }
            }

            if (!vibrantFound) {
                let totalBrightness = 0;
                const pixelCount = imgData.length / 4;
                for (let k = 0; k < imgData.length; k += 4) {
                    const rL = imgData[k] / 255;
                    const gL = imgData[k + 1] / 255;
                    const bL = imgData[k + 2] / 255;
                    totalBrightness += (0.299 * rL + 0.587 * gL + 0.114 * bL);
                }
                const avgBrightness = totalBrightness / pixelCount;
                root.extractedColor = avgBrightness < 0.5 ? "#D0D0D0" : "#404040";
                root.processed = true;
                return;
            }

            histogram[0] += histogram[35];

            let maxCount = -1;
            let winnerIdx = -1;
            for (let j = 0; j < 35; j++) {
                if (histogram[j] > maxCount) {
                    maxCount = histogram[j];
                    winnerIdx = j;
                }
            }

            if (winnerIdx !== -1 && sampleColors[winnerIdx]) {
                const finalColor = sampleColors[winnerIdx];
                const h = finalColor.hsvHue;
                const s = Math.max(0.35, Math.min(0.55, finalColor.hsvSaturation * 0.9));
                root.extractedColor = Qt.hsva(h, s, 0.95, 1.0);
                root.processed = true;
            }
        }
    }

    function captureSource() {
        if (!root.source || root.processed) {
            return;
        }

        root.source.grabToImage(function(result) {
            if (!result || !result.url) {
                return;
            }
            sampledImage.source = result.url;
        }, Qt.size(60, 60));
    }

    function restart() {
        processed = false;
        extractor.retries = 0;
        sampledImage.source = "";
        captureSource();
    }

    onSourceChanged: restart()
    Component.onCompleted: captureSource()
}
