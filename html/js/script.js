qbMultiCharacters = {};
let selectedChar = null;
let translations = {};
let NChar = null;
let EnableDeleteButton = false;
const WelcomePercentage = '30vh';

async function getBase64Image(src, callback, outputFormat) {
  const img = new Image();
  img.crossOrigin = 'Anonymous';
  img.addEventListener('load', () => loadFunc(), false);
  async function loadFunc() {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const convertingCanvas = canvas;
    canvas.height = img.naturalHeight;
    canvas.width = img.naturalWidth;
    ctx.drawImage(img, 0, 0);
    const dataURL = convertingCanvas.toDataURL(outputFormat);
    canvas.remove();
    convertingCanvas.remove();
    img.remove();
    callback(dataURL);
  }

  img.src = src;
  if (img.complete || img.complete === undefined) {
    img.src = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACEAAAAkCAIAAACIS8SLAAAAKklEQVRIie3NMQEAAAgDILV/55nBww8K0Enq2XwHDofD4XA4HA6Hw+E4Wwq6A0U+bfCEAAAAAElFTkSuQmCC';
    img.src = src;
  }
}

async function Convert(pMugShotTxd, id) {
  let tempUrl = `https://nui-img/${pMugShotTxd}/${pMugShotTxd}?t=${String(Math.round(new Date().getTime() / 1000))}`;
  if (pMugShotTxd == 'none') {
    tempUrl = 'https://cdn.discordapp.com/attachments/555420890444070912/983953950652903434/unknown.png';
  }
  getBase64Image(tempUrl, function (dataUrl) {
    $.post(
      `https://${GetParentResourceName()}/Answer`,
      JSON.stringify({
        Answer: dataUrl,
        Id: id,
      })
    );
  });
}

$(document).ready(function () {
  window.addEventListener('message', function (event) {
    const data = event.data;
    if (data.action == 'showPlayerCard') {
      renderCharacterInfo();
    }
    if (data.action == 'convert') {
      Convert(data.pMugShotTxd, data.id);
    }
    if (data.action == 'ui') {
      document.documentElement.style.setProperty('--primary-color', data.color || '#ff0000');
      document.documentElement.style.setProperty('--primary-color-80', `${data.color || '#ff0000'}80`);
      document.documentElement.style.setProperty('--primary-color-40', `${data.color || '#ff0000'}40`);
      NChar = data.nChar;
      EnableDeleteButton = data.enableDeleteButton;

      translations = data.translations;
      if (data.toggle) {
        $('.container').show();
        $('.welcomescreen').fadeIn(150);
        qbMultiCharacters.resetAll();

        let originalText = 'Loading.';
        let loadingProgress = 0;
        let loadingDots = 0;
        $('#loading-text').html(originalText);
        const DotsInterval = setInterval(function () {
          $('#loading-text').append('.');
          loadingDots++;
          loadingProgress++;
          if (loadingProgress == 3) {
            originalText = 'Loading..';
            $('#loading-text').html(originalText);
          }
          if (loadingProgress == 4) {
            originalText = 'Loading..';
            $('#loading-text').html(originalText);
          }
          if (loadingProgress == 6) {
            originalText = 'Loading...';
            $('#loading-text').html(originalText);
          }
          if (loadingDots == 4) {
            $('#loading-text').html(originalText);
            loadingDots = 0;
          }
        }, 500);

        setTimeout(function () {
          $.post('https://sys-multicharacter/setupCharacters');
          setTimeout(function () {
            clearInterval(DotsInterval);
            loadingProgress = 0;
            originalText = 'Retrieving data';
            $('.welcomescreen').fadeOut(150);
            qbMultiCharacters.fadeInDown('.characters-list', '15.6%', 1);
            qbMultiCharacters.fadeInDown('.bar', '14%', 1);
            qbMultiCharacters.fadeInDown('.bar2', '13.92%', 1);
            qbMultiCharacters.fadeInDown('.characters-icon', '1.66%', 1);
            qbMultiCharacters.fadeInDown('.characters-text', '5.26%', 1);
            qbMultiCharacters.fadeInDown('.characters-text2', '7.66%', 1);
            $('.btns').css({ display: 'flex' });
            $.post('https://sys-multicharacter/removeBlur');
            SetLocal();
          }, 500);
        }, 2000);
      } else {
        $('.container').fadeOut(250);
        qbMultiCharacters.resetAll();
      }
    }

    if (data.action == 'setupCharacters') {
      setupCharacters(event.data.characters);
    }
  });

  $('.datepicker').datepicker();
});

$('.continue-btn').click(function (e) {
  e.preventDefault();
});

$('.disconnect-btn').click(function (e) {
  e.preventDefault();

  $.post('https://sys-multicharacter/closeUI');
  $.post('https://sys-multicharacter/disconnectButton');
});

//Set Locale
function SetLocal() {
  $('.characters-text').html(translations['characters_header']);
}

function setupCharacters(characters) {
  $('.characters-text2').html(`${characters.length} / ${NChar} ${translations['characters_count']}`);
  setCharactersList(characters.length);
  $.each(characters, function (_, char) {
    $(`#character-${char.cid}`).html('');
    $(`#character-${char.cid}`).data('citizenid', char.citizenid);
    const tempUrl = char.image || translations['default_image'];
    setTimeout(function () {
      $(`#character-${char.cid}`).html(`
        <div class="character-parent">
          <div class="character-div">
            <div class="user">
              <img src="${tempUrl}" alt="${char.cid}photo" />
            </div>
            <div class="single-character-info">
              <p class="character-label"><i class="fa-solid fa-user"></i> ${char.charinfo.firstname} ${char.charinfo.lastname}</p>
              <p class="character-label"><i class="fa-solid fa-id-card"></i> ${char.citizenid}</p>
            </div>
            <span id="cid">${char.citizenid}</span>
            <div class="user3">
              <img src="${translations['default_right_image']}" alt="plus" /></div>
            </div>
          </div>
        </div>
        <div class="btns" style="">
          <div class="character-btn" id="select" style="display: block;">
            <p id="select-text">
              <i class="">${translations['select']}</i>
            </p>
          </div>
        </div>
        `);
      $(`#character-${char.cid}`).data('cData', char);
      $(`#character-${char.cid}`).data('cid', char.cid);
    }, 100);
  });
}

$(document).on('mouseleave', '.character', function (e) {
  const charId = $(this).attr('id');
  if (!charId) return;
  const id = charId.split('-')[1];
  $.post(
    'https://sys-multicharacter/CharacterUnHover',
    JSON.stringify({
      id,
    })
  );
});

$(document).on('mouseenter', '.character', function (e) {
  const charId = $(this).attr('id');
  if (!charId) return;
  const id = charId.split('-')[1];
  var audio = new Audio('assets/hover.mp3');
  audio.volume = 0.3;
  audio.play();
  $.post(
    'https://sys-multicharacter/CharacterHover',
    JSON.stringify({
      id,
    })
  );
});

const renderCharacterInfo = () => {
  const pedInfo = $(`#character-${selectedCharacterId}`).data('cData');
  const cash = new Intl.NumberFormat('en-US').format(pedInfo?.money?.cash || 0);
  const bank = new Intl.NumberFormat('en-US').format(pedInfo?.money?.bank || 0);
  const metadata = JSON.parse(pedInfo?.metadata || '{}');

  $('#char-job-label').html(pedInfo?.job?.label);
  $('#char-job-level').html(pedInfo?.job?.grade?.level);
  $('#char-gang-label').html(JSON.parse(pedInfo?.gang || '{}')?.label);
  $('#char-gang-level').html(JSON.parse(pedInfo?.gang || '{}')?.grade?.level || 'None');
  $('#char-iban').html(pedInfo?.charinfo?.account);
  $('#char-bank').html(`$ ${bank} USD`);
  $('#char-cash').html(`$ ${cash} USD`);
  $('#char-status').html(metadata?.isdead ? 'Dead' : metadata.inlaststand ? 'In Laststand' : 'Alive');
  $('#hunger-fill').css('width', `${metadata.hunger || 0}%`);
  $('#thirst-fill').css('width', `${metadata.thirst || 0}%`);
  $('#stress-fill').css('width', `${metadata.stress || 0}%`);
  $('#armor-fill').css('width', `${metadata.armor || 0}%`);
  $('.selected-character-info-container').css('transform', 'rotateY(-25deg)');
};

$(document).on('click', '#close-log', function (e) {
  e.preventDefault();
  selectedLog = null;
  $('.welcomescreen').css('filter', 'none');
  logOpen = false;
});
let selectedCharacterId = 0;
$(document).on('click', '.character', function (e) {
  const cDataPed = $(this).data('cData');
  e.preventDefault();
  if ($(this).data('cid') !== selectedCharacterId) {
    $(this).find('.user3 img').css('filter', 'grayscale(0)');
    $('.selected-character-info-container').css('transform', 'rotateY(-25deg) translate(550%, 0)');
  }
  if (selectedChar === null) {
    selectedChar = $(this);
    selectedCharacterId = $(this).data('cid');
    if (selectedChar.data('cid') == '') {
      $(selectedChar).addClass('character-selected');
      $('#play-text').html('<i class="fa-solid fa-plus"></i>');
      $('#delete').css({ display: 'block' });
      $(document).find('#char-del-btns').remove();
      $(this).find('.btns').find('.character-btn').remove();
      $(this).find('.btns').append(`
          <div class="character-btn" id="play" style="display: block;width: 100%;">
            <p id="play-text">${translations['create']}</p>
          </div>`);
      $.post(
        'https://sys-multicharacter/cDataPed',
        JSON.stringify({
          cData: cDataPed,
        })
      );
    } else {
      $(selectedChar).addClass('character-selected');
      $(document).find('#char-del-btns').remove();
      $(this).find('.btns').find('.character-btn').remove();

      if (EnableDeleteButton) {
        $(this)
          .find('.btns')
          .append(
            `
            <div class="character-btn" id="play" style="display: block;">
              <p id="play-text">${translations['spawn']}</p>
            </div>
            <div class="character-btn" id="delete" style="display: block;">
              <p id="delete-text">${translations['delete']}</p>
            </div>`
          );
      } else {
        $(this).find('.btns').append(`
            <div class="character-btn" id="play" style="display: block;width: 100%;">
              <p id="play-text">${translations['spawn']}</p>
            </div>`);
      }
      $('#play-text').html(`<i class="">${translations['spawn']}</i>`);
      $('#delete-text').html(`<i class="">${translations['delete']}</i>`);
      $.post(
        'https://sys-multicharacter/cDataPed',
        JSON.stringify({
          cData: cDataPed,
        })
      );
    }
  } else if ($(selectedChar).attr('id') !== $(this).attr('id')) {
    $(selectedChar).removeClass('character-selected');
    $(selectedChar).find('.btns').find('.character-btn').remove();
    $(this).find('.user3 img').css('filter', 'grayscale(0)');
    $(selectedChar).find('.btns').append(`
        <div class="character-btn" id="select" style="display: block;">
          <p id="select-text">
            <i class="">${translations['select']}</i>
          </p>
        </div>`);

    selectedChar = $(this);
    selectedCharacterId = $(this).data('cid');
    if (selectedChar.data('cid') == '') {
      $(selectedChar).addClass('character-selected');
      $('#play-text').html('<i class="fa-solid fa-plus"></i>');
      $(document).find('#char-del-btns').remove();
      $(this).find('.btns').find('.character-btn').remove();
      $(this).find('.btns').append(`<div class="character-btn" id="play" style=" display: block;width: 100%;"><p id="play-text">${translations['create']}</p></div>`);
      $('#delete').css({ display: 'none' });
    } else {
      $(selectedChar).addClass('character-selected');
      $(document).find('#char-del-btns').remove();
      $(this).find('.btns').find('.character-btn').remove();
      $(this).find('.user3 img').css('filter', 'grayscale(0)');
      if (EnableDeleteButton) {
        $(this).find('.btns').append(`
            <div class="character-btn" id="play" style="display: block;">
              <p id="play-text">${translations['spawn']}</p>
            </div>
            <div class="character-btn" id="delete" style="display: block;">
              <p id="delete-text">${translations['delete']}</p>
            </div>
            `);
      } else {
        $(this).find('.btns').append(`
            <div class="character-btn" id="play" style="display: block;width: 100%;">
              <p id="play-text">${translations['spawn']}</p>
            </div>`);
      }

      $('#play-text').html(`<i class="">${translations['spawn']}</i>`);
      $('#delete-text').html(`<i class="">${translations['delete']}</i>`);
      $.post(
        'https://sys-multicharacter/cDataPed',
        JSON.stringify({
          cData: cDataPed,
        })
      );
    }
  }
});

const entityMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
  '/': '&#x2F;',
  '': '&#x60;',
  '=': '&#x3D;',
};

function escapeHtml(string) {
  return String(string).replace(/[&<>"'=/]/g, function (s) {
    return entityMap[s];
  });
}
function hasWhiteSpace(s) {
  return /\s/g.test(s);
}

$(document).on('click', '#create', function (e) {
  e.preventDefault();
  $('.selected-character-info-container').css('transform', 'rotateY(-25deg) translate(550%, 0)');
  let firstname = $.trim(escapeHtml($('#first_name').val()));
  let lastname = $.trim(escapeHtml($('#last_name').val()));
  let nationality = $.trim(escapeHtml($('#nationality').val()));
  let birthdate = $.trim(escapeHtml($('#birthdate').val()));
  let gender = $.trim(escapeHtml($('input[name=radio]:checked').val()));

  let cid = $.trim(escapeHtml($(selectedChar).attr('id').replace('character-', '')));

  if (!firstname || !lastname || !nationality || !birthdate) {
    const reqFieldErr = `<p>${translations['missing_information']}</p>`;
    $('.error-msg').html(reqFieldErr);
    $('.error-title').html('<span class="material-symbols-outlined">&nbsp;</span>Error!');
    $('#cancel-error').html(translations['close']);

    $('.error').fadeIn(400);

    return false;
  }

  $.post(
    'https://sys-multicharacter/createNewCharacter',
    JSON.stringify({
      firstname: firstname,
      lastname: lastname,
      nationality: nationality,
      birthdate: birthdate,
      gender: gender,
      cid: cid,
    })
  );
  $('.container').fadeOut(150);
  $('.characters-list').css('filter', 'none');
  $('.character-info').css('filter', 'none');

  qbMultiCharacters.fadeOutDown('.character-register', '35%', 1);
  refreshCharacters();
});

$(document).on('click', '#accept-delete', function (e) {
  $('.selected-character-info-container').css('transform', 'rotateY(-25deg) translate(550%, 0)');
  $.post(
    'https://sys-multicharacter/removeCharacter',
    JSON.stringify({
      citizenid: $(selectedChar).data('citizenid'),
    })
  );
  $(document).find('#char-del-btns').remove();
  $('#delete').css({ display: 'block' });
  $('.characters-block').css('filter', 'none');
  refreshCharacters();
});

$(document).on('click', '#cancel-delete', function (e) {
  e.preventDefault();
  $(document).find('#char-del-btns').remove();
  $('#delete').css({ display: 'block' });
  $('.characters-block').css('filter', 'none');
});

$(document).on('click', '#close-error', function (e) {
  e.preventDefault();
  $('.characters-block').css('filter', 'none');
  $('.error').fadeOut(150);
});

function setCharactersList(max) {
  let htmlResult = '<div class="character-list-header"></div>';
  htmlResult += '<div class="characters">';
  if (max >= NChar) max = NChar - 1;
  for (let i = 1; i <= max + 1; i++) {
    htmlResult += `
    <div class="character" id="character-${i}" data-cid="">
      <div class="character-div">
        <span id="slot-name">${translations['create_new_character']}
          <span id="cid"></span>
        </span>
      </div>
      <div class="btns" style="">
        <div class="character-btn" id="select" style="display: block;">
          <p id="select-text">
            <i class="">${translations['select']}</i>
          </p>
        </div>
      </div>
    </div>`;
  }

  htmlResult += '</div>';
  $('.characters-list').html(htmlResult);
}

function refreshCharacters() {
  let htmlResult = '';
  for (let i = 1; i <= NChar; i++) {
    htmlResult += `
    <div class="character" id="character-${i}" data-cid="">
      <div class="character-div">
        <div class="user2"></div>
        <span id="slot-name">${translations['create_new_character']}
          <span id="cid"></span>
        </span>
        <div class="user2"></div>
      </div>
      <div class="btns" style="">
        <div class="character-btn" id="select" style="display: block;">
          <p id="select-text">
            <i class="">${translations['select']}</i>
          </p>
        </div>
      </div>
    </div>
    `;
  }

  $('.characters-list').html(htmlResult);

  setTimeout(function () {
    $(selectedChar).removeClass('character-selected');
    selectedChar = null;
    $.post('https://sys-multicharacter/setupCharacters');
    $('#delete').css({ display: 'none' });
    $('#play').css({ display: 'none' });
    qbMultiCharacters.resetAll();
  }, 100);
}

$(document).on('click', '#close-reg', function (e) {
  e.preventDefault();
  $('.error').fadeOut(150);
  $('.characters-list').css('filter', 'none');
  $('.character-info').css('filter', 'none');
  qbMultiCharacters.fadeOutDown('.character-register', '20%', 1);
  qbMultiCharacters.OpenAll();
});

$('#close-del').click(function (e) {
  e.preventDefault();
  $('.characters-block').css('filter', 'none');
});

$(document).on('click', '#play', function (e) {
  e.preventDefault();
  const charData = $(selectedChar).data('cid');
  if (selectedChar !== null) {
    if (charData !== '') {
      $.post(
        'https://sys-multicharacter/selectCharacter',
        JSON.stringify({
          cData: $(selectedChar).data('cData'),
        })
      );

      let counter = 1;
      let forceHide = setInterval(function () {
        if (counter == 20) {
          clearInterval(forceHide);
        } else {
          counter++;
        }
        $('.selected-character-info-container').css('transform', 'rotateY(-25deg) translate(550%, 0)');
      }, 100);
      setTimeout(function () {
        qbMultiCharacters.fadeOutDown('.characters-list', '-40%', 1);
        qbMultiCharacters.fadeOutDown('.bar', '-40%', 1);
        qbMultiCharacters.fadeOutDown('.characters-icon', '-40%', 1);
        qbMultiCharacters.fadeOutDown('.characters-text', '-40%', 1);
        qbMultiCharacters.fadeOutDown('.characters-text2', '-40%', 1);
        qbMultiCharacters.fadeOutDown('.character-info', '-40%', 1);
        $('.selected-character-info-container').css('transform', 'rotateY(-25deg) translate(550%, 0)');
        qbMultiCharacters.resetAll();
      }, 1500);
    } else {
      $('.characters-list').css('filter');
      $('.bar').css('filter');
      $('.characters-icon').css('filter');
      $('.characters-text').css('filter');
      $('.characters-text2').css('filter');
      $('.character-info').css('filter');

      $('.characters-register-block-header').html(`<p>${translations['create_header']}</p>`);
      $('.character-register-text').html(translations['header_detail']);

      $('.character-register-inputs').html(`
        <div class="input-div">
          <i class="fa-solid fa-address-card reg-icon" aria-hidden="true"></i>
          <input type="text" id="first_name" placeholder="${translations['create_firstname']}" class="character-reg-input" />
        </div>
        <div class="input-div">
          <i class="fa-solid fa-address-card reg-icon" aria-hidden="true"></i>
          <input type="text" id="last_name" placeholder="${translations['create_lastname']}" class="character-reg-input" />
        </div>
        <div class="input-div">
          <i class="fa-solid fa-globe reg-icon"></i>
          <input type="text" id="nationality" placeholder="${translations['create_nationality']}" class="character-reg-inputt2" />
        </div>
        <div class="input-div2">
          <i class="fa-solid fa-calendar reg-icon"></i>
          <input type="date" id="birthdate" placeholder="${translations['create_birthday']}" value="1971-01-01" min="1900-01-01" max="2023-12-31" class="character-reg-input" />
        </div>
        <div class="gender-title">${translations['choose_your_gender']}</div>
        <div class="gender-inputs-wrapper">
          <label>
            <input type="radio" name="radio" value="${translations['male']}" checked="checked" />
            <span><p>${translations['male']}</p></span>
          </label>
          <label>
            <input type="radio" name="radio" value="${translations['female']}" />
            <span><p>${translations['female']}</p></span>
          </label>
        </div>
        <div class="registeration-actions">
          <div class="character-reg-btn" id="create">
            <p id="create-text">Confirm</p>
          </div>
          <div class="character-reg-btn" id="close-reg">
            <p>Cancel</p>
          </div>
        </div>
      `);

      $('#create-text').html(translations['confirm']);
      $('#close-reg').html(`<p>${translations['cancel']}</p>`);
      qbMultiCharacters.fadeInDown('.character-register', '20%', 1);
      qbMultiCharacters.closeAll();
    }
  }
});

$(document).on('click', '#delete', function (e) {
  e.preventDefault();
  const charData = $(selectedChar).data('cid');

  if (selectedChar !== null) {
    if (charData !== '') {
      $('#delete').css({ display: 'none' });
      $('#delete')
        .parent()
        .append(
          `
          <div class="char-del-btns" id="char-del-btns">
            <div class="character-btn" id="accept-delete" style="display: flex;">
              <p><i class="fa-solid fa-check"></i></p>
            </div>
            <div class="character-btn" id="cancel-delete" style="display: flex;">
              <p><i class="fa-solid fa-times"></i></p>
            </div>
          </div>
          `
        );
    }
  }
});

qbMultiCharacters.fadeOutUp = function (element, time) {
  $(element)
    .css({ display: 'block' })
    .animate({ top: '-80.5%' }, time, function () {
      $(element).css({ display: 'none' });
    });
};

qbMultiCharacters.fadeOutDown = function (element, percent, time) {
  if (percent !== undefined) {
    $(element)
      .css({ display: 'block' })
      .animate({ top: percent }, time, function () {
        $(element).css({ display: 'none' });
      });
  } else {
    $(element)
      .css({ display: 'block' })
      .animate({ top: '103.5%' }, time, function () {
        $(element).css({ display: 'none' });
      });
  }
};

qbMultiCharacters.fadeInDown = function (element, percent, time) {
  $(element).css({ display: 'block' }).animate({ top: percent }, time);
};

qbMultiCharacters.closeAll = function () {
  $('.characters-list').hide();
  $('.bar').hide();
  $('.characters-text').hide();
  $('.characters-text2').hide();
  $('.characters-icon').hide();
  $('.character-info').hide();
  selectedChar = null;
};
qbMultiCharacters.OpenAll = function () {
  $('.characters-list').show();
  $('.bar').show();
  $('.characters-text').show();
  $('.characters-text2').show();
  $('.characters-icon').show();
  $('.character-info').show();
};
qbMultiCharacters.resetAll = function () {
  $('.characters-list').hide();
  $('.characters-list').css('top', '-40');
  $('.bar').hide();
  $('.characters-text').hide();
  $('.characters-text2').hide();
  $('.characters-icon').hide();
  $('.character-info').hide();
  $('.welcomescreen').css('top', WelcomePercentage);
  selectedChar = null;
};
