require 'gtk2'

class Factory < Gtk::Window
  def initialize
    super
  end

  def edit_factory(title,input_text,text,&response) #text will be used soon
    @control = false
    buffer = Gtk::TextBuffer.new
    buffer.insert_interactive_at_cursor(input_text, true)
    textentry = Gtk::TextView.new(buffer)
    dialog = Gtk::Dialog.new(title,
                             self,
                             Gtk::Dialog::MODAL,       
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    dialog.signal_connect("response") {
      response.call(buffer,dialog)
    }
    dialog.signal_connect("key-press-event") { |inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) =~ /^Control/
        @control = true
      elsif Gdk::Keyval.to_name(ev.keyval) == "Return"
        if @control
          dialog.signal_emit("response", Gtk::Dialog::RESPONSE_NONE)
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
      if Gdk::Keyval.to_name(ev.keyval) == "Return"
        dialog.signal_emit("response", 0)
      end
    }
    dialog.signal_connect("response") {
      response.call(input,dialog)
    }
    dialog.vbox.pack_start(linha)
    dialog.show_all
  end
end
