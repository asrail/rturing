require 'gtk2'
require 'turing/machine'



class Factory < Gtk::Window
  def initialize
    super
  end

  def validate(machine, dialog)
    begin
      t = Turing::TransFunction.new(machine,Turing::MTRegex.new(Turing::Machine.default_kind))
      return true
    rescue Turing::InvalidMachine
      value = false
      message = "A máquina de turing digitada não é válida."
      d2 = Gtk::MessageDialog.new(dialog,
                                  Gtk::MessageDialog::MODAL,
                                  Gtk::MessageDialog::INFO,
                                  Gtk::MessageDialog::BUTTONS_CLOSE,
                                  message)
      d2.run {}
      d2.destroy
      return false
    end
  end

  def edit_factory(title,input_text,text,&response) #text will be used soon
    Gtk::Stock.add(Gtk::Stock::APPLY, "_Validar")
    
    @control = false
    buffer = Gtk::TextBuffer.new
    buffer.insert_interactive_at_cursor(input_text, true)
    textentry = Gtk::TextView.new(buffer)
    textentry.accepts_tab = false
    dialog = Gtk::Dialog.new(title,
                             self,
                             Gtk::Dialog::MODAL,
                             [Gtk::Stock::APPLY, Gtk::Dialog::RESPONSE_APPLY],
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK],
                             [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL])
    dialog.signal_connect("response") {|dia, action|
      if action == Gtk::Dialog::RESPONSE_OK
        if validate(buffer.text, dialog)
          response.call(buffer,dialog, response)
        end
      elsif action == Gtk::Dialog::RESPONSE_APPLY
        validate(buffer.text, dialog)
      else
        dialog.destroy
      end
    }
    dialog.signal_connect("key-press-event") { |inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) =~ /^Control/
        @control = true
      elsif ev.keyval == Gdk::Keyval::GDK_Return or ev.keyval == Gdk::Keyval::GDK_KP_Enter
        if @control
          dialog.signal_emit("response", Gtk::Dialog::RESPONSE_OK)
          @control = false
        end
      end
    }
    dialog.signal_connect("key-release-event") { |inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) =~ /^Control/
        @control = false
      end
    }
    dialog.vbox.pack_start(textentry)
    dialog.set_default_size(200,100)
    dialog.show_all
  end

  def choose_factory(title,input_text,text,&response)
    linha = Gtk::HBox.new
    label = Gtk::Label.new(text) # 0 parameter... la la la...
    linha.pack_start(label)
    input = Gtk::Entry.new
    input.text = input_text #1 parameter
    linha.pack_start(input)
    dialog = Gtk::Dialog.new(title, #2 parameters
                             self,
                             Gtk::Dialog::MODAL,
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    input.signal_connect("key_press_event") {|inp, ev|
      if ev.keyval == Gdk::Keyval::GDK_Return or ev.keyval == Gdk::Keyval::GDK_KP_Enter
        dialog.signal_emit("response", 0)
      end
    }
    dialog.signal_connect("response") {
      response.call(input,dialog)
    }
    dialog.vbox.pack_start(linha)
    dialog.set_default_size(200,-1)
    dialog.show_all
  end
end
