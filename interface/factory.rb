require 'gtk2'
require 'turing/machine'
require "interface/widget/configentry"



class Factory < Gtk::Dialog
  def initialize(a,b,*c)
    super(a,b,*c)
  end

  def validate(machine, dialog)
    begin
      t = Turing::TransFunction.new(machine,Turing::Machine.default_kind)
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
end

class EditDialog < Factory
  def initialize(title,input_text,text,&response) #text will be used soon
    Gtk::Stock.add(Gtk::Stock::APPLY, "_Validar")
    
    @control = false
    buffer = Gtk::TextBuffer.new
    buffer.insert_interactive_at_cursor(input_text.to_s, true)
    textentry = Gtk::TextView.new(buffer)
    textentry.accepts_tab = false
    layout = Gtk::Layout.new
    scroll = Gtk::ScrolledWindow.new
    scroll.add(textentry)
    scroll.hscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.vscrollbar_policy = Gtk::POLICY_AUTOMATIC
    super(title,
          nil,
          Gtk::Dialog::MODAL,
          [Gtk::Stock::APPLY, Gtk::Dialog::RESPONSE_APPLY],
          [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK],
          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL])
    signal_connect("response") {|dia, action|
      if action == Gtk::Dialog::RESPONSE_OK
        if validate(buffer.text, self)
          response.call(buffer, self, response)
        end
      elsif action == Gtk::Dialog::RESPONSE_APPLY
        validate(buffer.text, self)
      else
        destroy
      end
    }
    signal_connect("key-press-event") { |inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) =~ /^Control/
        @control = true
      elsif ev.keyval == Gdk::Keyval::GDK_Return or ev.keyval == Gdk::Keyval::GDK_KP_Enter
        if @control
          signal_emit("response", Gtk::Dialog::RESPONSE_OK)
          @control = false
        end
      end
    }
    signal_connect("key-release-event") { |inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) =~ /^Control/
        @control = false
      end
    }
    vbox.pack_start(scroll)
    set_default_size(340,480)
    show_all
  end
end

class ChooseDialog < Factory
  def initialize(title,input_text,text,config,&response)
    linha = Gtk::HBox.new
    label = Gtk::Label.new(text)
    linha.pack_start(label)
    if config
      input = ConfigEntry.new(config, input_text)
    else
      input = Gtk::Entry.new
      input.text = input_text.to_s
    end
    linha.pack_start(input)
    super(title,
          nil,
          Gtk::Dialog::MODAL,
          [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    input.signal_connect("key_press_event") {|inp, ev|
      if ev.keyval == Gdk::Keyval::GDK_Return or ev.keyval == Gdk::Keyval::GDK_KP_Enter
        signal_emit("response", 0)
      end
    }
    signal_connect("response") {
      response.call(input,self)
    }
    vbox.pack_start(linha)
    set_default_size(200,-1)
    show_all
  end
end
