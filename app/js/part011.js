
      var _cdWords = [], _cdImg = "https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778571475/grok_image_1778520937416_jazknf.jpg";
      // Per-category banner URLs — swap in real images when Ribon provides them
      var _catBanners = {
        'off50':    _cdImg, 'elements': _cdImg, 'sacred':  _cdImg,
        'identity': _cdImg, 'cosmos':   _cdImg, 'nature':  _cdImg,
        'family':   _cdImg, 'elite':    _cdImg, 'premium': _cdImg,
        'mythical': _cdImg, 'warriors': _cdImg, 'ancient': _cdImg,
        'peace':    _cdImg, 'white':    _cdImg, 'black':   _cdImg
      };
      function openCatDetail(catId, catName, words) {
        _cdWords = words;
        document.getElementById('rmCatDetailTitle').textContent = catName;
        document.getElementById('rmCatDetailCount').textContent = words.length + ' words';
        document.getElementById('rmCatDetailSearch').value = '';
        renderCatDetail(words);
        // Banner
        var bImg   = document.getElementById('rmCatdBannerImg');
        var bTitle = document.getElementById('rmCatdBannerTitle');
        if (bImg)   { bImg.classList.remove('loaded'); bImg.src = _catBanners[catId] || _cdImg; }
        if (bTitle) bTitle.textContent = catName;
        var el = document.getElementById('rmCatDetail');
        el.style.display = 'flex';
        setTimeout(function(){ el.classList.add('open'); }, 10);
      }
      function closeCatDetail() {
        document.getElementById('rmCatDetail').classList.remove('open');
        setTimeout(function(){ document.getElementById('rmCatDetail').style.display = 'none'; }, 200);
      }
      function filterCatDetail(q) {
        var filtered = q ? _cdWords.filter(function(w){ return w[0].toLowerCase().indexOf(q.toLowerCase()) > -1; }) : _cdWords;
        renderCatDetail(filtered);
      }
      function renderCatDetail(words) {
        var grid = document.getElementById('rmCatDetailGrid');
        grid.innerHTML = words.map(function(w){
          var name = w[0], root = w[1];
          var cap = name.charAt(0).toUpperCase()+name.slice(1);
          // Generate a subtle gradient per word for visual variety
          var hue = (name.charCodeAt(0) * 37 + name.charCodeAt(name.length-1) * 19) % 360;
          var price = (name.length <= 4 ? 49 : name.length <= 6 ? 79 : 99);
          return '<div class="rm-catd-card" onclick="closeCatDetail();setTimeout(function(){loadWordOrigin(\''+name+'\')},250)" style="background:linear-gradient(135deg,rgba('+Math.round(Math.sin(hue)*30+20)+','+Math.round(Math.sin(hue+2)*20+15)+','+Math.round(Math.sin(hue+4)*40+30)+',0.95),rgba(6,12,24,0.98));border:1px solid rgba(255,255,255,0.09);">'
            + '<div class="rm-catd-overlay"></div>'
            + '<div class="rm-catd-card-body">'
            + '<div class="rm-catd-card-name" style="font-size:18px;font-weight:800;color:#fff;font-family:\'DM Sans\',sans-serif;letter-spacing:.5px;">'+cap+'</div>'
            + '<div class="rm-catd-card-root" style="font-size:10px;color:rgba(255,255,255,.45);font-family:\'DM Sans\',sans-serif;letter-spacing:1px;text-transform:uppercase;margin-top:3px;">'+root+'</div>'
            + '<div style="margin-top:10px;font-size:11px;font-weight:700;color:rgba(232,213,163,.8);font-family:\'DM Sans\',sans-serif;">$'+(price/100).toFixed(2)+'</div>'
            + '</div>'
            + '</div>';
        }).join('');
      }
      