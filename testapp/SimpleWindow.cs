using System;
using System.Windows.Forms;

class SimpleWindow : Form
{
    public SimpleWindow()
    {
        this.Text = "Simple Window";
        this.Width = 400;
        this.Height = 300;
    }

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.Run(new SimpleWindow());
    }
}
