import Croppie from "../../vendor/croppie.js";

export default {
  mounted() {
    const input = document.getElementById("image-cropper-input");
    let cr;

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
