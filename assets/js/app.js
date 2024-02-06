import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let hooks = {
  ImageCropper: {
    async mounted() {
      const { default: ImageCropper } = await import("./hooks/ImageCropper");
      ImageCropper.mounted.call(this);
    },
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks,
});

topbar.config({
  barColors: {
    0: "rgba(253, 0, 0, .25)",
    ".5": "rgba(253, 186, 116, .5)",
    1: "rgba(253, 186, 116, 1)",
  },
  shadowColor: "rgba(0, 0, 0, .3)",
  barThickness: 5,
});

window.addEventListener("phx:page-loading-start", (info) => {
  topbar.show(300);

  if (info.detail.kind === "redirect") {
    const main = document.querySelector("main");
    main?.classList.add("phx-page-loading");
  }
});
window.addEventListener("phx:page-loading-stop", (info) => {
  topbar.hide();

  if (info.detail.kind === "redirect") {
    const main = document.querySelector("main");
    main?.classList.remove("phx-page-loading");
  }
});

liveSocket.connect();

window.liveSocket = liveSocket;
