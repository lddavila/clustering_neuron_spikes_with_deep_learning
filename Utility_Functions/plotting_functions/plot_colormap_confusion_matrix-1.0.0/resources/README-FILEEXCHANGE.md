# A ColorMap(HeatMap)Style Confusion Matrix

This code is an alternative to the MATLAB functions `plotconfusion` and `confusionchart`.

# _How to Use?_

```
[ConfMat,Accuracy] = CmapConfusionMatrix(Actual_Labels,Predicted_Labels,Cmap);
```

- _`ConfMat`_ : Confusion Matrix
- _`Accuracy`_ : Accuracy of Classification
- _`Actual_Labels`_ : True Labels
- _`Predicted_Labels`_ : Output Labels
- _`Cmap`_ : Colormap Style
  - _`Colormap Name`_ : Select from the table below

If no `Cmap` argument is provided, a popup window will appear asking you to select one of the listed colormaps, and if you ignore this step or try to choose default colormap, default option will be selected automatically.(like the below)

[![snip](https://user-images.githubusercontent.com/96732467/201543726-27d7b757-fe9b-4f5d-b394-dd0d859059bb.PNG)](https://user-images.githubusercontent.com/96732467/201543726-27d7b757-fe9b-4f5d-b394-dd0d859059bb.PNG)

# _`HeatMap Styles`_

<markdown-accessiblity-table><table class="readme_table">
<thead>
<tr>
<th class="readme_th">Colormap Name</th>
<th class="readme_th">Color Scale</th>
</tr>
</thead>
<tbody>
<tr>
<td class="readme_td"><code>parula</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/a540cb7ff9b904691c8f5ebb2ea1ced5d48ffcb598d1d0366936bb011c6c7a1e/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f706172756c615f7570646174653137612e706e67"><img src="https://camo.githubusercontent.com/a540cb7ff9b904691c8f5ebb2ea1ced5d48ffcb598d1d0366936bb011c6c7a1e/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f706172756c615f7570646174653137612e706e67" alt="colormap_winter" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_parula_update17a.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>turbo</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/2b3221a5514398be65ef166d3b62de3e853d651fbeac1621acb097057737da9d/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f747572626f2e706e67"><img src="https://camo.githubusercontent.com/2b3221a5514398be65ef166d3b62de3e853d651fbeac1621acb097057737da9d/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f747572626f2e706e67" alt="colormap_turbo" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_turbo.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>hsv</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/66e18dee90f97f3356e45a36b010cf4ee89cfd37b2029e5e43febfe583e12dd3/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f6873762e706e67"><img src="https://camo.githubusercontent.com/66e18dee90f97f3356e45a36b010cf4ee89cfd37b2029e5e43febfe583e12dd3/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f6873762e706e67" alt="colormap_hsv" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_hsv.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>hot	</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/22660a1eb3309a6b2f396ccd985839c2c1dcfab72231fa11c119e5818e848c81/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f686f742e706e67"><img src="https://camo.githubusercontent.com/22660a1eb3309a6b2f396ccd985839c2c1dcfab72231fa11c119e5818e848c81/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f686f742e706e67" alt="colormap_hot" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_hot.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>cool</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/d4f6ab6c6bc02c37649d875467106492eb13d4433018d3828966e6913f3eb6b4/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f636f6f6c2e706e67"><img src="https://camo.githubusercontent.com/d4f6ab6c6bc02c37649d875467106492eb13d4433018d3828966e6913f3eb6b4/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f636f6f6c2e706e67" alt="colormap_cool" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_cool.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>spring</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/250bcecb8bfada43bd7c5a08a2a840652f3ca55e8660e8fbaccae5de012408c0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f737072696e672e706e67"><img src="https://camo.githubusercontent.com/250bcecb8bfada43bd7c5a08a2a840652f3ca55e8660e8fbaccae5de012408c0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f737072696e672e706e67" alt="colormap_spring" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_spring.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>summer</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/a3ecde4eb53911e4400becc171661e5473e16ab58f7fd4d97750118aeaa417f0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f73756d6d65722e706e67"><img src="https://camo.githubusercontent.com/a3ecde4eb53911e4400becc171661e5473e16ab58f7fd4d97750118aeaa417f0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f73756d6d65722e706e67" alt="colormap_summer" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_summer.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>autumn</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/57e1bdf39b9a27140412cf73f1c4ea1935d3d4d9dea66ad1971d742c7d254af0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f617574756d6e2e706e67"><img src="https://camo.githubusercontent.com/57e1bdf39b9a27140412cf73f1c4ea1935d3d4d9dea66ad1971d742c7d254af0/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f617574756d6e2e706e67" alt="colormap_autumn" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_autumn.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>winter</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/46ad96592dbc538a8ff2ab6e7b55637ca29b928b64e83042403dea0e0b2675e3/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f77696e7465722e706e67"><img src="https://camo.githubusercontent.com/46ad96592dbc538a8ff2ab6e7b55637ca29b928b64e83042403dea0e0b2675e3/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f77696e7465722e706e67" alt="colormap_winter" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_winter.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>gray</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/e8947178490fe186812fbed8af7687f546e00c9b9374012173bd3f124d7e5ae8/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f677261792e706e67"><img src="https://camo.githubusercontent.com/e8947178490fe186812fbed8af7687f546e00c9b9374012173bd3f124d7e5ae8/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f677261792e706e67" alt="colormap_gray" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_gray.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>bone</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/dc07ad22488ca84eb4fa1adb83947157eb0a19c0ad35429f1f58fedde3af4986/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f626f6e652e706e67"><img src="https://camo.githubusercontent.com/dc07ad22488ca84eb4fa1adb83947157eb0a19c0ad35429f1f58fedde3af4986/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f626f6e652e706e67" alt="colormap_bone" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_bone.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>copper</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/187b2939894d660b6148b3cc5a2bed7b5605755c10742dffbb2bdb9aaf78d75e/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f636f707065722e706e67"><img src="https://camo.githubusercontent.com/187b2939894d660b6148b3cc5a2bed7b5605755c10742dffbb2bdb9aaf78d75e/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f636f707065722e706e67" alt="colormap_copper" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_copper.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>pink</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/2508510d60bdf0775980f1aaa2ecb8879861993ac298c7d19aa5281a845950e7/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f70696e6b2e706e67"><img src="https://camo.githubusercontent.com/2508510d60bdf0775980f1aaa2ecb8879861993ac298c7d19aa5281a845950e7/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f70696e6b2e706e67" alt="colormap_pink" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_pink.png" style="max-width: 100%;"></a></td>
</tr>
<tr>
<td class="readme_td"><code>jet</code></td>
<td class="readme_td"><a target="_blank" rel="nofollow noopener noreferrer" href="https://camo.githubusercontent.com/671162664c32058339205a8cdbdb07d8bcc64571b441986a61fe07c368815654/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f6a65742e706e67"><img src="https://camo.githubusercontent.com/671162664c32058339205a8cdbdb07d8bcc64571b441986a61fe07c368815654/68747470733a2f2f6e6c2e6d617468776f726b732e636f6d2f68656c702f6d61746c61622f7265662f636f6c6f726d61705f6a65742e706e67" alt="colormap_jet" data-canonical-src="https://nl.mathworks.com/help/matlab/ref/colormap_jet.png" style="max-width: 100%;"></a></td>
</tr>
</tbody>
</table></markdown-accessiblity-table>

# _`Output using summer ColorMap`_

[![colorconf](https://user-images.githubusercontent.com/96732467/201543208-13c06f32-c826-45a2-b94f-6358692fad75.jpg)](https://user-images.githubusercontent.com/96732467/201543208-13c06f32-c826-45a2-b94f-6358692fad75.jpg)

* * *

[![Mail](https://camo.githubusercontent.com/490453ac3d8a7c4152e8aa9cdc8310bb912ceb732b16d6ec42000420b522f596/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f476d61696c2d666172686161642e61626564696e7a616465253430676d61696c2e636f6d2d637269746963616c3f7374796c653d666c61742d737175617265266c6f676f3d676d61696c)](https://github.com/farhadabedinzadeh/ColorHeatMap_ConfusionMatrix/blob/main/)