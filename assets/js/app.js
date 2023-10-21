import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Croppie from "../vendor/croppie.js"

let ImageCropper = {
  mounted() {
    const input = document.getElementById('image-cropper-input')
    let cr

    const field = this.el.getAttribute('data-name') || 'profile_picture' // Default to profile_picture for compatibility reasons 

    const viewport = {
      type: this.el.getAttribute('data-type') || 'square',
      width: parseFloat(this.el.getAttribute('data-width')) || 320,
      height: parseFloat(this.el.getAttribute('data-height')) || 320
    }

    input.addEventListener('input', _ => {
      const [imageFile] = input.files
      const url = URL.createObjectURL(imageFile)

      document.getElementById('croppie')?.remove()

      const div = document.createElement('div')
      div.id = 'croppie'
      div.src = url
      this.el.appendChild(div)

      cr = new Croppie(div, {
        url,
        boundary: {
          height: 600,
        },
        viewport,
      })
    })

    document.getElementById('done-button').addEventListener('click', async _ => {
      if (!cr || !input.files.length) {
        return
      }

      const blob = await cr.result({ type: 'blob' })
      const file = new File([blob], 'upload', { type: blob.type })

      this.upload(field, [file])
    })
  }
}

let hooks = { ImageCropper }

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks })

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()

window.liveSocket = liveSocket
