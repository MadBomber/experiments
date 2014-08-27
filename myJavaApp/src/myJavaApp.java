//
//  myJavaApp.java
//  myJavaApp
//
//  Created by Dewayne VanHoozer on 8/16/09.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//
//	For information on setting Java configuration information, including 
//	setting Java properties, refer to the documentation at
//		http://developer.apple.com/techpubs/java/java.html
//

import java.util.Locale;
import java.util.ResourceBundle;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;

import javax.swing.*;

import com.apple.eawt.*;

public class myJavaApp extends JFrame {

	private Font font = new Font("serif", Font.ITALIC+Font.BOLD, 36);
	protected ResourceBundle resbundle;
	protected AboutBox aboutBox;
	protected PrefPane prefs;
	private Application fApplication = Application.getApplication();
	protected Action newAction, openAction, closeAction, saveAction, saveAsAction,
					 undoAction, cutAction, copyAction, pasteAction, clearAction, selectAllAction;
	static final JMenuBar mainMenuBar = new JMenuBar();	
	protected JMenu fileMenu, editMenu; 
	
	public myJavaApp() {
		
		super("");
		// The ResourceBundle below contains all of the strings used in this
		// application.  ResourceBundles are useful for localizing applications.
		// New localities can be added by adding additional properties files.
		resbundle = ResourceBundle.getBundle ("strings", Locale.getDefault());
		setTitle(resbundle.getString("frameConstructor"));
		this.getContentPane().setLayout(null);
		
		createActions();
		addMenus();

		fApplication.setEnabledPreferencesMenu(true);
		fApplication.addApplicationListener(new com.apple.eawt.ApplicationAdapter() {
			public void handleAbout(ApplicationEvent e) {
                                if (aboutBox == null) {
                                    aboutBox = new AboutBox();
                                }
                                about(e);
                                e.setHandled(true);
			}
			public void handleOpenApplication(ApplicationEvent e) {
			}
			public void handleOpenFile(ApplicationEvent e) {
			}
			public void handlePreferences(ApplicationEvent e) {
                                if (prefs == null) {
                                    prefs = new PrefPane();
                                }
				preferences(e);
			}
			public void handlePrintFile(ApplicationEvent e) {
			}
			public void handleQuit(ApplicationEvent e) {
				quit(e);
			}
		});
		
		setSize(310, 150);
		setVisible(true);
	}

	public void about(ApplicationEvent e) {
		aboutBox.setResizable(false);
		aboutBox.setVisible(true);
	}

	public void preferences(ApplicationEvent e) {
		prefs.setResizable(false);
		prefs.setVisible(true);
	}

	public void quit(ApplicationEvent e) {	
		System.exit(0);
	}

	public void createActions() {
		int shortcutKeyMask = Toolkit.getDefaultToolkit().getMenuShortcutKeyMask();

		//Create actions that can be used by menus, buttons, toolbars, etc.
		newAction = new newActionClass( resbundle.getString("newItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_N, shortcutKeyMask) );
		openAction = new openActionClass( resbundle.getString("openItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_O, shortcutKeyMask) );
		closeAction = new closeActionClass( resbundle.getString("closeItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_W, shortcutKeyMask) );
		saveAction = new saveActionClass( resbundle.getString("saveItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_S, shortcutKeyMask) );
		saveAsAction = new saveAsActionClass( resbundle.getString("saveAsItem") );

		undoAction = new undoActionClass( resbundle.getString("undoItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_Z, shortcutKeyMask) );
		cutAction = new cutActionClass( resbundle.getString("cutItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_X, shortcutKeyMask) );
		copyAction = new copyActionClass( resbundle.getString("copyItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_C, shortcutKeyMask) );
		pasteAction = new pasteActionClass( resbundle.getString("pasteItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_V, shortcutKeyMask) );
		clearAction = new clearActionClass( resbundle.getString("clearItem") );
		selectAllAction = new selectAllActionClass( resbundle.getString("selectAllItem"),
											KeyStroke.getKeyStroke(KeyEvent.VK_A, shortcutKeyMask) );
	}
	
	public void addMenus() {

		fileMenu = new JMenu(resbundle.getString("fileMenu"));
		fileMenu.add(new JMenuItem(newAction));
		fileMenu.add(new JMenuItem(openAction));
		fileMenu.add(new JMenuItem(closeAction));
		fileMenu.add(new JMenuItem(saveAction));
		fileMenu.add(new JMenuItem(saveAsAction));
		mainMenuBar.add(fileMenu);

		editMenu = new JMenu(resbundle.getString("editMenu"));
		editMenu.add(new JMenuItem(undoAction));
		editMenu.addSeparator();
		editMenu.add(new JMenuItem(cutAction));
		editMenu.add(new JMenuItem(copyAction));
		editMenu.add(new JMenuItem(pasteAction));
		editMenu.add(new JMenuItem(clearAction));
		editMenu.addSeparator();
		editMenu.add(new JMenuItem(selectAllAction));
		mainMenuBar.add(editMenu);

		setJMenuBar (mainMenuBar);
	}

	public void paint(Graphics g) {
		super.paint(g);
		g.setColor(Color.blue);
		g.setFont (font);
		g.drawString(resbundle.getString("message"), 40, 80);
	}
	
	public class newActionClass extends AbstractAction {
		public newActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("New...");
		}
	}

	public class openActionClass extends AbstractAction {
		public openActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Open...");
		}
	}
	
	public class closeActionClass extends AbstractAction {
		public closeActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Close...");
		}
	}
	
	public class saveActionClass extends AbstractAction {
		public saveActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Save...");
		}
	}
	
	public class saveAsActionClass extends AbstractAction {
		public saveAsActionClass(String text) {
			super(text);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Save As...");
		}
	}
	
	public class undoActionClass extends AbstractAction {
		public undoActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Undo...");
		}
	}
	
	public class cutActionClass extends AbstractAction {
		public cutActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Cut...");
		}
	}
	
	public class copyActionClass extends AbstractAction {
		public copyActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Copy...");
		}
	}
	
	public class pasteActionClass extends AbstractAction {
		public pasteActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Paste...");
		}
	}
	
	public class clearActionClass extends AbstractAction {
		public clearActionClass(String text) {
			super(text);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Clear...");
		}
	}
	
	public class selectAllActionClass extends AbstractAction {
		public selectAllActionClass(String text, KeyStroke shortcut) {
			super(text);
			putValue(ACCELERATOR_KEY, shortcut);
		}
		public void actionPerformed(ActionEvent e) {
			System.out.println("Select All...");
		}
	}
	
	 public static void main(String args[]) {
		new myJavaApp();
	 }

}