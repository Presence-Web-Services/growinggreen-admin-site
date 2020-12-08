<script>
let fileInput, title, passphrase;
let titleError, passphraseError, photosError;
let responseError, responseSuccess;
let sending;
$: disabled = titleError || passphraseError || photosError || sending;
let photos = [];

function removePhoto(index) {
  photos.splice(index, 1);
  photos = photos;
}

function upPhoto(index) {
  if (index === 0) {
    return;
  }
  let tmp = photos[index];
  photos[index] = photos[index - 1];
  photos[index - 1] = tmp;
}

function downPhoto(index) {
  if (index === photos.length - 1) {
    return;
  }
  let tmp = photos[index];
  photos[index] = photos[index + 1];
  photos[index + 1] = tmp;
}

function loadPhotos() {
  photosError = responseError = responseSuccess = '';
  for (let i = 0; i < fileInput.files.length; i++) {
    photos[i] = {};
    photos[i]['photo'] = fileInput.files[i];
    let reader = new FileReader();
    reader.onload = (event) => {
      photos[i]['src'] = event.target.result;
    };
    reader.readAsDataURL(photos[i]['photo']);
    photos[i]['caption'] = '';
  }
}

function titleChange() {
  titleError = responseError = '';
}

function passphraseChange() {
  passphraseError = responseError = '';
}

function checkTitle() {
  if (!title) {
    titleError = 'Error: Please enter a title.';
    return;
  }
  else if (title.length > 100) {
    titleError = 'Error: Title is too long.';
    return;
  }
}

function checkPassphrase() {
  if (!passphrase) {
    passphraseError = 'Error: Please enter a passphrase.';
    return;
  }
  else if (passphrase.length > 100) {
    passphraseError = 'Error: Passphrase is too long.';
    return;
  }
}

function checkPhotos() {
  if (photos.length === 0) {
    photosError = 'Error: Please select photo(s) to upload.';
    return;
  }
}

function clearFields() {
  title = passphrase = '';
  photos = [];
}

function uploadPhotos() {
  let promises = [];
  const now = new Date();
  const dateString = `${now.getFullYear()}_${now.getMonth()+1}_${now.getDate()}_${now.getHours()}_${now.getMinutes()}_${now.getSeconds()}`;
  for (let i = 0; i < photos.length; i++) {
    delete photos[i].src;
    promises.push(uploadPhoto(i, dateString));
  }
  promises.push(sendEmail(dateString));
  Promise.all(promises).then(() => {
    responseSuccess = 'Photo(s) successfully uploaded.';
    clearFields();
    sending = false;
  }).catch(error => {
    responseError = error;
    sending = false;
  });
}

function uploadPhoto(index, dateString) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();
    formData.append('passphrase', passphrase);
    formData.append('index', index);
    formData.append('date', dateString);
    formData.append('photo', photos[index]['photo']);
    xhr.addEventListener('load', (event) => {
      if (event.target.status == 200) {
        resolve(event.target.responseText.trim());
      } else {
        reject(event.target.responseText.trim());
      }
    });
    xhr.addEventListener('error', (event) => {
      reject('Error: No response from server.');
    });
    xhr.open('POST', '/upload/');
    xhr.send(formData);
  });
}

function sendEmail(dateString) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();
    formData.append('title', title);
    formData.append('passphrase', passphrase);
    formData.append('date', dateString);
    formData.append('numPhotos', photos.length);
    for (let i = 0; i < photos.length; i++) {
      formData.append('caption'+i, photos[i]['caption'])
    }
    xhr.addEventListener('load', (event) => {
      if (event.target.status == 200) {
        resolve(event.target.responseText.trim());
      } else {
        reject(event.target.responseText.trim());
      }
    });
    xhr.addEventListener('error', (event) => {
      reject('Error: No response from server.');
    });
    xhr.open('POST', '/email/');
    xhr.send(formData);
  });
}

function upload() {
  titleError = passphraseError = photosError = responseError = responseSuccess = '';
  sending = true;
  checkTitle();
  checkPassphrase();
  checkPhotos();
  if (titleError || passphraseError || photosError) {
    sending = false;
    return;
  }
  uploadPhotos();
}
</script>

<form>
  <input type="file" accept="image/jpeg, image/png" multiple bind:this={fileInput} on:change={loadPhotos}>
  <input type="text" placeholder="Title" maxlength="100" size="33" required bind:value={title} on:input={titleChange}>
  {#each photos as photo, index}
    <p>{photo.photo.name}</p>
    <img src={photo.src} alt={photo.photo.name} width="200">
    <input type="text" placeholder="Caption" maxlength="100" size="33" bind:value={photo.caption}>
    <div>
      <button class="control" id="delete" on:click|preventDefault={() => removePhoto(index)}>X</button>
      <button class="control updown" on:click|preventDefault={() => upPhoto(index)}>Up</button>
      <button class="control updown" on:click|preventDefault={() => downPhoto(index)}>Down</button>
    </div>
  {/each}
  <input type="text" placeholder="Passphrase" maxlength="100" size="33" required bind:value={passphrase} on:input={passphraseChange}>
  <button id="upload" on:click|preventDefault={upload} {disabled}>Upload</button>
</form>
{#if titleError}
  <p aria-live="polite" class="error">{titleError}</p>
{/if}
{#if passphraseError}
  <p aria-live="polite" class="error">{passphraseError}</p>
{/if}
{#if photosError}
  <p aria-live="polite" class="error">{photosError}</p>
{/if}
{#if responseError}
  <p aria-live="polite" class="error">{responseError}</p>
{/if}
{#if responseSuccess}
  <p aria-live="polite" class="success">{responseSuccess}</p>
{/if}
{#if sending}
  <p aria-live="polite">Please wait while the photo(s) are being uploaded.</p>
{/if}


<style>
form {
  display: flex;
  flex-direction: column;
  align-items: center;
}
form * {
  display: block;
}
form input {
  font-size: 1em;
  max-width: 100%;
  margin-top: 1em;
}
form p {
  min-width: initial;
}
img {
  width: 200px;
}
button.control {
  display: inline-block;
  padding: 0.3em;
}
#delete {
  margin-right: 2em;
}
#upload {
  margin: 1em;
  padding: 0.3em;
}
#upload:disabled {
  background-color: #cccccc;
  color: black;
}
p.error {
  color: red;
}
p.success {
  color: green;
}
</style>
