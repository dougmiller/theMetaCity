document.addEventListener("DOMContentLoaded", function () {
    "use strict";

    var searchBox = document.getElementById("mediaSearchBox");
    var toSearch = document.getElementsByClassName("mediaEntry");
    var noMediaFound = document.getElementById("noMediaFound");
    var searchTimeout;

    noMediaFound.style.display = "none";

    searchBox.addEventListener("input", function () {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            if (this.value.length) {
                var rePattern = this.value.replace(/[.?*+^$\[\]\\(){}|]/g, "\\$&");
                var searchPattern = new RegExp('(' + rePattern + ')', 'ig');
                filter(searchPattern);
            } else {
                resetSearch();
            }
        }, 500);
    });


    function filter(searchRegex) {
        var noMediaDisplay = true;
        for (var i = 0; i < toSearch.length; i++) {
            var h1a = toSearch[i].getElementsByTagName("h1")[0].getElementsByTagName("a")[0];
            var tags = toSearch[i].getElementsByClassName("tags")[0].getElementsByTagName("li");

            toSearch[i].style.display = 'none';
            if (h1a.textContent.match(searchRegex)) {
                h1a.innerHTML = h1a.textContent.replace(searchRegex, '<span class="searchMatchTitle">$1</span>');
                toSearch[i].style.display = 'block';
            } else {
                h1a.innerHTML = h1a.textContent;
            }

            for (var j = 0; j < tags.length; j++) {
                var tagA = tags[j].getElementsByTagName("a")[0];
                if (tagA.textContent.match(searchRegex)) {
                    tagA.innerHTML = tags[j].textContent.replace(searchRegex, '<span class="searchMatchTag">$1</span>');
                    toSearch[i].style.display = 'block';
                    noMediaFound.style.display = "block";
                } else {
                    tagA.innerHTML = tags[j].textContent;
                    console.log(tags[j].textContent);
                }
            }
        }

        if (noMediaDisplay){
            noMediaFound.style.display = "block";
        } else {
            noMediaFound.style.display = "none";
        }
    }

    function resetSearch() {
        noMediaFound.style.display = "none";
        for (var i = 0; i < toSearch.length; i++) {
            var h1a = toSearch[i].getElementsByTagName("h1")[0].getElementsByTagName("a")[0];
            var tags = toSearch[i].getElementsByClassName("tags")[0].getElementsByTagName("li");

            h1a.innerHTML = h1a.textContent;
            for (var j = 0; j < tags.length; j++) {
                var tagA = tags[j].getElementsByTagName("a")[0];
                tagA.innerHTML = tagA.textContent;
            }
            toSearch[i].style.display = "block";
        }
    }
});