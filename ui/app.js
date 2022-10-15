const { createApp } = Vue

  createApp({
    data() {
      return {
        password: null,
        visible: false,
        error: null, 
        config: {},
        attempts: 0,
      }
    },
    mounted() {
        window.addEventListener('message', this.onMessage);
    },
    destroyed() {
        window.removeEventListener('message')
    },
    methods: {
        onMessage(event) {
            if (event.data.type === 'toggle') {
              this.visible = event.data.visible
              this.config = event.data.config
            }

            if (event.data.type === 'passcr') {
              let status = event.data.status
              this.attempts = event.data.attempts
              
              if (status == false) {
                this.error = this.config.lang.error
              } else {
                this.visible = false
              }
            }
        },
        checkPassword() {
          this.error = null
          fetch(`https://${GetParentResourceName()}/checkpass`, {
            method: 'POST',
            body: JSON.stringify({
              password: this.password
            })
          })
        }
    }
  }).mount('#app')