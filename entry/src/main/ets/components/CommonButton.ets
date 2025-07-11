// File: entry/src/main/ets/components/CommonButton.ets

@Component
export struct CommonButton {
  text: string = '';
  icon?: string;
  type: 'primary' | 'secondary' | 'danger' = 'primary';
  disabled: boolean = false;
  onButtonClick?: () => void;

  build() {
    Column() {
      Button() {
        Row({ space: 8 }) {
          if (this.icon) {
            Text(this.icon)
              .fontSize(16)
              .fontColor(this.type === 'secondary' ? '#374151' : Color.White)
          }
          Text(this.text)
            .fontSize(15)
            .fontColor(this.type === 'secondary' ? '#374151' : Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(this.type === 'primary' ? '#007DFF' : 
                     this.type === 'secondary' ? '#F9FAFB' : '#EF4444')
      .borderRadius(8)
      .shadow({ 
        radius: 6, 
        color: this.type === 'primary' ? '#007DFF30' : 
               this.type === 'secondary' ? '#00000008' : '#EF444430', 
        offsetX: 0, 
        offsetY: 3 
      })
      .opacity(this.disabled ? 0.5 : 1)
      .onClick(() => {
        if (!this.disabled && this.onButtonClick) {
          this.onButtonClick();
        }
      })
    }
  }
} 