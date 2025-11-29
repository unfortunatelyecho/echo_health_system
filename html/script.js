let hudVisible = false;
let therapyTimer = null;

$(document).ready(function() {
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch(data.action) {
            case 'toggleHUD':
                toggleHUD();
                break;
            case 'updateMental':
                updateMentalHealth(data.mental);
                break;
            case 'updateAddiction':
                updateAddiction(data.substance, data.level);
                break;
            case 'showOrganList':
                showOrganList(data.organs);
                break;
            case 'refreshOrgans':
                $('#organMenu').fadeOut();
                break;
            case 'startTherapy':
                startTherapy(data.duration);
                break;
        }
    });
    
    // Close modals
    $('.close').click(function() {
        $(this).closest('.modal').fadeOut();
        $.post('https://echo_health_system/closeUI', JSON.stringify({}));
    });
    
    // Close on ESC
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            $('.modal').fadeOut();
            $.post('https://echo_health_system/closeUI', JSON.stringify({}));
        }
    });
});

function toggleHUD() {
    hudVisible = !hudVisible;
    if (hudVisible) {
        $('#hud').removeClass('hidden').fadeIn();
    } else {
        $('#hud').fadeOut();
    }
}

function updateMentalHealth(mental) {
    $('#mentalBar').css('width', mental + '%');
    $('#mentalText').text(mental + '%');
    
    // Color based on value
    if (mental >= 80) {
        $('#mentalBar').css('background', 'linear-gradient(90deg, #00ff00, #90ee90)');
    } else if (mental >= 60) {
        $('#mentalBar').css('background', 'linear-gradient(90deg, #90ee90, #ffff00)');
    } else if (mental >= 40) {
        $('#mentalBar').css('background', 'linear-gradient(90deg, #ffff00, #ffa500)');
    } else {
        $('#mentalBar').css('background', 'linear-gradient(90deg, #ffa500, #ff0000)');
    }
    
    // Auto-show HUD
    if (!hudVisible) {
        $('#hud').removeClass('hidden').fadeIn();
        hudVisible = true;
    }
}

function updateAddiction(substance, level) {
    let addictionEl = $(`#addiction-${substance}`);
    
    if (addictionEl.length === 0) {
        $('#addictionsContainer').append(`
            <div class="addiction-item" id="addiction-${substance}">
                <div class="label">${capitalizeFirst(substance)} Addiction</div>
                <div class="bar-container">
                    <div class="bar addiction-bar" style="width: ${level}%;">
                        <span>${Math.round(level)}%</span>
                    </div>
                </div>
            </div>
        `);
    } else {
        addictionEl.find('.addiction-bar').css('width', level + '%').find('span').text(Math.round(level) + '%');
    }
    
    // Remove if cured
    if (level <= 0) {
        addictionEl.fadeOut(function() {
            $(this).remove();
        });
    }
}

function showOrganList(organs) {
    let html = '';
    
    if (organs.length === 0) {
        html = '<p style="color: #ccc; text-align: center;">No organs available</p>';
    } else {
        organs.forEach(organ => {
            const quality = organ.quality;
            let qualityClass = 'quality-low';
            if (quality >= 80) qualityClass = 'quality-high';
            else if (quality >= 50) qualityClass = 'quality-medium';
            
            html += `
                <div class="organ-item" data-id="${organ.id}">
                    <h3>${capitalizeFirst(organ.organ_type)}</h3>
                    <p>Blood Type: <strong>${organ.blood_type}</strong></p>
                    <p>Quality: <span class="organ-quality ${qualityClass}">${quality}%</span></p>
                    <p>Price: <strong>$${organ.is_black_market ? organ.price * 3.5 : organ.price}</strong></p>
                </div>
            `;
        });
    }
    
    $('#organList').html(html);
    $('#organMenu').fadeIn();
    
    // Click handler
    $('.organ-item').click(function() {
        const organId = $(this).data('id');
        $.post('https://echo_health_system/purchaseOrgan', JSON.stringify({
            organId: organId,
            isBlackMarket: false
        }));
        $('#organMenu').fadeOut();
    });
}

function startTherapy(duration) {
    $('#therapyUI').fadeIn();
    
    let timeLeft = duration;
    const totalTime = duration;
    
    therapyTimer = setInterval(function() {
        timeLeft--;
        
        const progress = ((totalTime - timeLeft) / totalTime) * 100;
        $('#therapyProgress').css('width', progress + '%');
        
        const minutes = Math.floor(timeLeft / 60);
        const seconds = timeLeft % 60;
        $('#therapyTime').text(`${minutes}:${seconds.toString().padStart(2, '0')}`);
        
        if (timeLeft <= 0) {
            clearInterval(therapyTimer);
            $('#therapyUI').fadeOut();
        }
    }, 1000);
}

function capitalizeFirst(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}