$(document).ready(function() {
    $("#dropdown-button").on("click", function() {
        var dropdown = document.getElementById("dropdown-menu");
        var dropdown_arrow = document.getElementById("dropdown-arrow");
        var isHidden = dropdown.classList.contains("hidden");
        if (isHidden) {
            dropdown.classList.remove("hidden");
            dropdown_arrow.classList.remove("menu-arrow-down");
            dropdown_arrow.classList.add("menu-arrow-up");
        } else {
            dropdown.classList.add("hidden");
            dropdown_arrow.classList.remove("menu-arrow-up");
            dropdown_arrow.classList.add("menu-arrow-down");
        }
    });
});

function go_back() {
    var from_yodel = document.referrer.indexOf(location.protocol + "//" + location.host) === 0;
    if (from_yodel) {
        try {
            var from_channel = document.referrer.split("?")[1].split("=")[0] === "channel";
        } catch {}
        if (from_channel) {
            document.location = "/channels";
        } else {
            history.back();
        }
    } else {
        document.location = "/";
    }
}

function create_menu(id, is_owner, is_comment = false) {
    var dim = document.getElementById("dim");
    dim.classList.remove("hidden");
    
    var options_frame = document.createElement("div");
    options_frame.setAttribute("id", "options-frame");

    var options_separator = document.createElement("hr");
    options_separator.setAttribute("class", "options-separator");

    var close_button = document.createElement("span");
    close_button.setAttribute("onclick", "document.getElementById('options-frame').outerHTML = ''; document.getElementById('dim').classList.add('hidden');");
    close_button.innerHTML = "CLOSE";

    if (is_owner) {
        var link1 = document.createElement("a");
        if (is_comment) {
            link1.setAttribute("href", `/comment/${id}/delete`);
            link1.innerHTML = "Delete comment";
        } else {
            link1.setAttribute("href", `/post/${id}/delete`);
            link1.innerHTML = "Delete post";
        }
    } else {
        var link1 = document.createElement("span");
        link1.setAttribute("onclick", "alert('Coming Soon™')");
        link1.innerHTML = "Report abuse";
    }
    var link2 = document.createElement("span");
    link2.setAttribute("onclick", "alert('Coming Soon™')");
    link2.innerHTML = "Move to channel";

    var link3 = document.createElement("span");
    link3.setAttribute("onclick", "alert('Coming Soon™')");
    link3.innerHTML = "Hide this post";

    options_frame.appendChild(link1);
    options_frame.appendChild(options_separator);
    options_frame.appendChild(link2);
    options_frame.appendChild(options_separator.cloneNode());
    options_frame.appendChild(link3);
    options_frame.appendChild(options_separator.cloneNode());
    options_frame.appendChild(close_button);

    document.body.appendChild(options_frame);
}

function upvote(post_id, comment_id) {
    if (comment_id == 0) {
        var type = "post";
        var rating = document.getElementById(`${type}-${post_id}`);
    } else {
        var type = "comment";
        var rating = document.getElementById(`${type}-${comment_id}`);
    }

    var votes = parseInt(rating.innerHTML);

    if (type == "post") {
        $.post(window.location.origin + `/post/${post_id}/vote/up`, function(data) {
            rating.innerHTML = ++votes;
        });
    } else if (type == "comment") {
        $.post(window.location.origin + `/post/${post_id}/comment/${comment_id}/vote/up`, function(data) {
            rating.innerHTML = ++votes;
        });
    }

    // Disable vote buttons
    var parent = rating.parentNode;
    parent.childNodes[1].removeAttribute("onclick");
    parent.childNodes[3].removeAttribute("onclick");
    parent.childNodes[1].setAttribute("disabled", "disabled");
    parent.childNodes[3].setAttribute("disabled", "disabled");
}

function downvote(post_id, comment_id) {
    if (comment_id == 0) {
        var type = "post";
        var rating = document.getElementById(`${type}-${post_id}`);
    } else {
        var type = "comment";
        var rating = document.getElementById(`${type}-${comment_id}`);
    }

    var votes = parseInt(rating.innerHTML);

    if (type == "post") {
        $.post(window.location.origin + `/post/${post_id}/vote/down`, function(data) {
            rating.innerHTML = --votes;
        });
    } else if (type == "comment") {
        $.post(window.location.origin + `/post/${post_id}/comment/${comment_id}/vote/down`, function(data) {
            rating.innerHTML = --votes;
        });
    }

    // Disable vote buttons
    var parent = rating.parentNode;
    parent.childNodes[1].removeAttribute("onclick");
    parent.childNodes[3].removeAttribute("onclick");
    parent.childNodes[1].setAttribute("disabled", "disabled");
    parent.childNodes[3].setAttribute("disabled", "disabled");
}

function pin(id) {
    $.post(window.location.origin + `/post/pin/${id}`, function(data) {
        var pin = document.getElementById("pin-post");
        pin.setAttribute("onclick", `unpin(${id})`);
        pin.classList.remove("pin");
        pin.classList.add("pinned");
    });
}

function unpin(id) {
    $.post(window.location.origin + `/post/unpin/${id}`, function(data) {
        var pin = document.getElementById("pin-post");
        pin.setAttribute("onclick", `pin(${id})`);
        pin.classList.remove("pinned");
        pin.classList.add("pin");
    });
}