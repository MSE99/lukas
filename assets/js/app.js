import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

import Croppie from "../vendor/croppie.js";

const closeAllToolbars = () => {
  document
    .querySelectorAll(".tox-toolbar__overflow")
    .forEach((el) => el.remove());
};

let Editor = {
  mounted() {
    const initialContent = this.el.getAttribute("data-original-content") || "";

    tinymce.init({
      selector: "#lesson-editor",
      height: 600,
      plugins: [
        "advlist",
        "autolink",
        "lists",
        "link",
        "image",
        "charmap",
        "preview",
        "anchor",
        "searchreplace",
        "visualblocks",
        "code",
        "fullscreen",
        "insertdatetime",
        "media",
        "table",
        "help",
        "wordcount",
        "directionality",
      ],
      toolbar:
        "undo redo | blocks | " +
        "bold italic backcolor image | alignleft aligncenter " +
        "alignright alignjustify | bullist numlist outdent indent | " +
        "removeformat | help | ltr rtl",
      content_style:
        "body { font-family:Helvetica,Arial,sans-serif; font-size:16px }",
      placeholder: "Type something here...",
      setup(editor) {
        editor.on("init", () => {
          editor.setContent(initialContent);
        });
      },
    });

    const editor = tinymce.get("lesson-editor");

    const pushEventHandler = () => {
      const content = editor.getContent();
      this.pushEventTo(this.el, "text-editor", { text_content: content });
    };

    const onChangeHandler = () => {
      closeAllToolbars();
      pushEventHandler();
    };

    this.handleEvent("tinymce_reset", () => {
      editor.resetContent();
      pushEventHandler();
    });

    editor.on("keyup", onChangeHandler);
    editor.on("change", onChangeHandler);
  },
};

let ImageCropper = {
  mounted() {
    const input = document.getElementById("image-cropper-input");
    let cr;

    const field = this.el.getAttribute("data-name") || "profile_picture"; // Default to profile_picture for compatibility reasons

    const viewport = {
      type: this.el.getAttribute("data-type") || "square",
      width: parseFloat(this.el.getAttribute("data-width")) || 320,
      height: parseFloat(this.el.getAttribute("data-height")) || 320,
    };

    input.addEventListener("input", (_) => {
      const [imageFile] = input.files;
      const url = URL.createObjectURL(imageFile);

      document.getElementById("croppie")?.remove();

      const div = document.createElement("div");
      div.id = "croppie";
      div.src = url;
      this.el.appendChild(div);

      cr = new Croppie(div, {
        url,
        boundary: {
          height: 600,
        },
        viewport,
      });
    });

    document
      .getElementById("crop-button")
      .addEventListener("click", async (_) => {
        const blob = await cr.result({ type: "blob" });
        const file = new File([blob], "upload", { type: blob.type });

        const transfer = new DataTransfer();
        transfer.items.add(file);

        const fileInput = document.querySelector(".live-file-input");
        fileInput.files = transfer.files;

        fileInput.dispatchEvent(new Event("change", { bubbles: true }));
      });
  },
};

let hooks = { ImageCropper, Editor };

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
