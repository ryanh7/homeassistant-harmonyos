@Component
export struct HaLogo {
  @Prop
  logoSize: number = 64;

  build() {
    Image($r('app.media.ha_brand'))
      .objectFit(ImageFit.Contain)
      .width(this.logoSize)
      .height(this.logoSize)
  }
}
