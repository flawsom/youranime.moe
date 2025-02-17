var tags = document.getElementsByClassName("tag");
var tagValues = [];

[].forEach.call(tags, function(tag) {
    var value = tag.getAttribute("value");
    tag.onclick = function(e) {
        if (tag.classList.contains("current-show")) {
            return;
        }
        if (tag.classList.contains("active")) {
            tag.classList.remove("active");
            tagValues.splice(tagValues.indexOf(value), 1);
        } else {
            tag.classList.add("active");
            tagValues.push(value);
        }
        checkReset();
        getResults();
    }
    var pre_selected_tag = Config.getParameterByName("selected");
    if (pre_selected_tag) {
        if (pre_selected_tag == value) {
            var event = document.createEvent("MouseEvents");
            event.initEvent("click", true, true);
            event.synthetic = true;
            tag.dispatchEvent(event, true);
        }
    }
});

function checkReset() {
    var button = document.getElementById("reset-btn");
    button.onclick = function(e) {
        tagValues = [];
        [].forEach.call(tags, function(tag) {
            tag.classList.remove("active");
        });
        checkReset();
    }
    if (tagValues.length == 0) {
        button.classList.add("disabled");
        document.getElementById("results").innerHTML = "";
    } else {
        button.classList.remove("disabled");
    }
}

function compareTags(tl1, tl2) {
    // tl1 has to be in tl2, so...
    if (tl2.length == 0) {
        return false;
    }
    var found = true;
    [].forEach.call(tl1, function(current_tag) {
        if (!tl2.includes(current_tag)) {
            found = false;
        }
        if (!found) {return;}
    });
    return found;
}

function build(show, host) {
    var icon = host + "/" + show.image_path;
    var html = [
        '<div class="col m3">',
            '<a href="/shows?id=' + show.id + '">',
                '<img src="' + icon + '"/>',
                '<p>' + (show.alternate_title || show.title) + '</p>',
            '</a>',
        '</div>'
    ]
    return html.join("");
}

function drawShows(shows, host) {
    var html = [
        '<div class="row">',
    ];

    [].forEach.call(shows, function(show) {
        var c = compareTags(tagValues, show.tags);
        if (!c) {
            return;
        }
        var show_html = build(show, host);
        html.push(show_html);
    });

    html.push('</div>');

    return html.join("");
}

function getResults() {
    $.ajax({
        url: "/api/get/shows",
        method: 'post',
        data: 'token='+ token + '&get_host=true',
        success: function(res) {
            if (res.success === true) {
                if (tagValues.length == 0) {
                    document.getElementById("results").innerHTML = "";
                } else {
                    var host = res.get_host;
                    res = res.shows;
                    var html = drawShows(res, host);
                    document.getElementById("results").innerHTML = html;
                }
            }
        }
    });
}
