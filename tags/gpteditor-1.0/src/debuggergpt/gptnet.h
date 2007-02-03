/***************************************************************************
 *   Copyright (C) 2003-2006 by Thiago Silva                               *
 *   thiago.silva@kdemail.net                                              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#ifndef GPTNET_H
#define GPTNET_H

#include <qobject.h>
#include <kurl.h>

#include "debuggergpt.h"

class Connection;
class DebuggerGPT;
class QSocket;
class QDomElement;

class GPTNet : public QObject {
  Q_OBJECT
public:
  GPTNet(DebuggerGPT*, QObject* parent = 0, const char* name = 0);
  ~GPTNet();

  bool startListener();

//   void setCurrentURL(const KURL& url);

  void requestContinue();
  void requestStop();
  void requestStepInto();
  void requestStepOver();
  void requestStepOut();

  //   void requestWatch(const QString& expression, int ctx_id = 0);
  //   void requestVariables(int scope, int id);
  //
    void requestBreakpoint(const QString&, int line);
    void requestBreakpointRemoval(const QString&, int line);

signals:
  void sigGPTStarted();
  void sigGPTClosed();

private slots:
  void slotIncomingConnection(QSocket*);
  void slotGPTClosed();
  void slotError(const QString&);

  void slotReadBuffer();

private:
  void processXML(const QString& xml);
  void processStack(QDomElement&);
  void processVariables(QDomElement&);

  DebuggerGPT* m_debugger;
  Connection* m_con;
  QSocket* m_socket;  
};

#endif